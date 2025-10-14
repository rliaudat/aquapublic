import 'package:flutter/material.dart';

class MeterReadingProvider extends ChangeNotifier {
  bool _isOCREnabled = true;
  bool _hasReadings = false;

  bool get isOCREnabled => _isOCREnabled;
  bool get hasReadings => _hasReadings;

  void setIsOCREnabled(bool value) {
    _isOCREnabled = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setHasReading(bool value) {
    _hasReadings = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void reset() {
    _isOCREnabled = true;
    _hasReadings = false;
  }
}
