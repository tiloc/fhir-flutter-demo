import 'dart:convert';

import 'package:fhir/r4/r4.dart';
import 'package:research_package/model.dart';

class RPFhirQuestionnaire {
  String _getText(QuestionnaireItem item) {
    return item.textElement?.extension_[0].valueString ?? item.text;
  }

  final Questionnaire _questionnaire;

  RPAnswerFormat _buildChoiceAnswers(QuestionnaireItem element) {
    var choices = <RPChoice>[];

    if (element.answerValueSet != null) {
      final key =
          element.answerValueSet.value.substring(1); // Strip off leading '#'
      var i = 0;
      (_questionnaire.contained
                  .firstWhere((element) => (element.id.toString() == key))
              as ValueSet)
          .compose
          .include
          .first
          .concept
          .forEach((element) {
        choices.add(RPChoice.withParams(element.display, i++));
      });
    } else {
      var i =
          0; // TODO: Don't forget to put the real values back into the response...
      element.answerOption?.forEach((choice) {
        choices.add(RPChoice.withParams(choice.valueCoding.display, i++));
      });
    }

    return RPChoiceAnswerFormat.withParams(
        ChoiceAnswerStyle.SingleChoice, choices);
  }

  List<RPQuestionStep> _buildQuestionSteps(QuestionnaireItem item, int level) {
    final steps = <RPQuestionStep>[];

    final optional = !(item.required_?.value ?? true);

    switch (item.type) {
      case QuestionnaireItemType.choice:
        steps.add(RPQuestionStep.withAnswerFormat(
            item.linkId, _getText(item), _buildChoiceAnswers(item),
            optional: optional));
        break;
      case QuestionnaireItemType.string:
        steps.add(RPQuestionStep.withAnswerFormat(
            item.linkId,
            _getText(item),
            RPChoiceAnswerFormat.withParams(ChoiceAnswerStyle.SingleChoice,
                [RPChoice.withParams(_getText(item), 0, true)]),
            optional: optional));
        break;
      case QuestionnaireItemType.decimal:
        steps.add(RPQuestionStep.withAnswerFormat(item.linkId, _getText(item),
            RPIntegerAnswerFormat.withParams(0, 999999),
            optional:
                optional)); // Unfortunately, surveys are using "Decimal" when they are clearly expecting integers.
        break;
      default:
        print('Unsupported question item type: ${item.type.toString()}');
    }
    return steps;
  }

  List<RPStep> _buildSteps(QuestionnaireItem item, int level) {
    var steps = <RPStep>[];

    switch (item.type) {
      case QuestionnaireItemType.group:
        steps.add(RPInstructionStep(
          identifier: item.linkId,
          detailText:
              'Please fill out this survey.\n\nIn this survey the questions will come after each other in a given order. You still have the chance to skip some of them, though.',
          title: item.code?.first?.display,
        )..text = item.text);

        item.item.forEach((groupItem) {
          steps.addAll(_buildSteps(groupItem, level + 1));
        });
        break;
      case QuestionnaireItemType.choice:
      case QuestionnaireItemType.string:
      case QuestionnaireItemType.decimal:
        steps.addAll(_buildQuestionSteps(item, level));
        break;
      default:
        print('Unsupported item type: ${item.type.toString()}');
    }
    return steps;
  }

  List<RPStep> _rpStepsFromFhirQuestionnaire() {
    final toplevelSteps = <RPStep>[];
    _questionnaire.item.forEach((item) {
      toplevelSteps.addAll(_buildSteps(item, 0));
    });

    return toplevelSteps;
  }

  QuestionnaireResponseItem _fromGroupItem(
      QuestionnaireItem item, RPTaskResult result) {
    final nestedItems = <QuestionnaireResponseItem>[];
    item.item.forEach((nestedItem) {
      if (nestedItem.type == QuestionnaireItemType.group) {
        nestedItems.add(_fromGroupItem(nestedItem, result));
      } else {
        final responseItem = _fromQuestionItem(nestedItem, result);
        if (responseItem != null) nestedItems.add(responseItem);
      }
    });
    return QuestionnaireResponseItem(
        linkId: item.linkId, text: item.text, item: nestedItems);
  }

  QuestionnaireResponseItem? _fromQuestionItem(
      QuestionnaireItem item, RPTaskResult result) {
    // TODO: Support more response types
    final RPStepResult? resultStep = result.results[item.linkId];
    if (resultStep == null) {
      print('No result found for linkId ${item.linkId}');
      return null;
    }
    final resultForIdentifier = resultStep.getResultForIdentifier('answer');
    if (resultForIdentifier == null) {
      print('No answer for ${item.linkId}');
      return QuestionnaireResponseItem(
          linkId: item.linkId, text: resultStep.questionTitle, answer: []);
    }
    switch (item.type) {
      case QuestionnaireItemType.choice:
        final rpChoice = (resultForIdentifier as List<RPChoice>).first;
        return QuestionnaireResponseItem(
            linkId: item.linkId,
            text: resultStep.questionTitle,
            answer: [
              QuestionnaireResponseAnswer(valueString: rpChoice.text)
            ]); // TODO: Use Coding?
      default:
        print('${item.type} not supported');
        return QuestionnaireResponseItem(linkId: item.linkId);
    }
  }

  QuestionnaireResponse fhirQuestionnaireResponse(
      RPTaskResult result, QuestionnaireResponseStatus status) {
    final questionnaireResponse = QuestionnaireResponse(
        status: status, item: <QuestionnaireResponseItem>[]);

    _questionnaire.item.forEach((item) {
      if (item.type == QuestionnaireItemType.group) {
        questionnaireResponse.item.add(_fromGroupItem(item, result));
      } else {
        final responseItem = _fromQuestionItem(item, result);
        if (responseItem != null) questionnaireResponse.item.add(responseItem);
      }
    });

    return questionnaireResponse;
  }

  RPCompletionStep completionStep() {
    return RPCompletionStep('completionID')
      ..title = 'Finished'
      ..text = 'Thank you for filling out the survey!';
  }

  RPOrderedTask surveyTask() {
    return RPOrderedTask(
      'surveyTaskID',
      [..._rpStepsFromFhirQuestionnaire(), completionStep()],
    );
  }

  RPFhirQuestionnaire(String jsonFhirQuestionnaire)
      : _questionnaire =
            Questionnaire.fromJson(json.decode(jsonFhirQuestionnaire));
}
