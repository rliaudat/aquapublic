import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class MeterCameraProvider extends ChangeNotifier {
  String _reading = '';
  bool _isCameraControllerInit = false;
  XFile? _originalImage;
  Uint8List? _webImageBytes;

  String get reading => _reading;
  bool get isCameraControllerInit => _isCameraControllerInit;
  XFile? get originalImage => _originalImage;
  Uint8List? get webImageBytes => _webImageBytes;

  void setReading(String value) {
    _reading = value;
    notifyListeners();
  }

  void setIsCameraControllerInit(bool value) {
    _isCameraControllerInit = value;
    notifyListeners();
  }

  void setOriginalImage(XFile? value) {
    _originalImage = value;
    notifyListeners();
  }

  void setWebImageBytes(Uint8List? value) {
    _webImageBytes = value;
    notifyListeners();
  }

  void reset() {
    _reading = '';
    _isCameraControllerInit = false;
    _originalImage = null;
    _webImageBytes = null;
  }
}
