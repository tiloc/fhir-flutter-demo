import 'dart:convert';

import 'package:fhir/r4/r4.dart';
import 'package:research_package/model.dart';

class RPFhirQuestionnaire {
  String _getText(QuestionnaireItem item) {
    return item.textElement?.extension_[0].valueString ?? item.text;
  }

  RPAnswerFormat _buildAnswers(QuestionnaireItem element) {
    var choices = <RPChoice>[];
    var i = 0;
    element.answerOption?.forEach((choice) {
      choices.add(RPChoice.withParams(choice.valueCoding.display, i++));
    });

    return RPChoiceAnswerFormat.withParams(
        ChoiceAnswerStyle.SingleChoice, choices);
  }

  List<RPQuestionStep> _buildQuestionSteps(QuestionnaireItem item, int level) {
    final steps = <RPQuestionStep>[];

    switch (item.type) {
      case QuestionnaireItemType.choice:
        steps.add(RPQuestionStep.withAnswerFormat(
            item.linkId, _getText(item), _buildAnswers(item)));
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
          title: item.code.first.display,
        )..text = item.text);

        item.item.forEach((groupItem) {
          steps.addAll(_buildSteps(groupItem, level + 1));
        });
        break;
      case QuestionnaireItemType.choice:
        steps.addAll(_buildQuestionSteps(item, level));
        break;
      default:
        print('Unsupported item type: ${item.type.toString()}');
    }
    return steps;
  }

  List<RPStep> fhirQuestionnaire(String jsonFhirQuestionnaire) {
    final fhirQuestionnaire =
        Questionnaire.fromJson(json.decode(jsonFhirQuestionnaire));

    final toplevelSteps = <RPStep>[];
    fhirQuestionnaire.item.forEach((item) {
      toplevelSteps.addAll(_buildSteps(item, 0));
    });

    return toplevelSteps;
  }

  RPCompletionStep completionStep() {
    return RPCompletionStep('completionID')
      ..title = 'Finished'
      ..text = 'Thank you for filling out the survey!';
  }

  RPOrderedTask surveyTask(String jsonFhirQuestionnaire) {
    return RPOrderedTask(
      'surveyTaskID',
      [...fhirQuestionnaire(jsonFhirQuestionnaire), completionStep()],
    );
  }
}
