import 'package:fhir/r4.dart';

extension SafeDisplayQuestionnaireAnswerOptionExtensions
    on QuestionnaireAnswerOption {
  String get safeDisplay {
    return this.valueCoding?.safeDisplay ?? this.toString();
  }
}

extension SafeDisplayCodingExtensions on Coding {
  String get safeDisplay {
    return this.display ?? this.code?.value ?? this.toString();
  }
}

extension SafeDisplayListCodingExtensions on List<Coding> {
  /// A safeguarded way to get a display value or null
  String? get safeDisplay {
    if (this.isEmpty) return null;
    return this.first.safeDisplay;
  }
}

extension FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull {
    return (this.isEmpty) ? null : this.first;
  }
}
