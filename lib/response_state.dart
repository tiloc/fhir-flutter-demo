import 'package:fhir/r4/resource_types/clinical/diagnostics/diagnostics.dart';
import 'package:flutter/foundation.dart';

class ResponseModel extends ChangeNotifier {
  QuestionnaireResponse? _response;

  QuestionnaireResponse? get response => _response;

  void setResponse(QuestionnaireResponse response) {
    _response = response;
    notifyListeners();
  }
}
