import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ReadingBottomSheetProvider extends ChangeNotifier {
  File? _image;
  Uint8List? _webImage;

  File? get image => _image;
  Uint8List? get webImage => _webImage;

  void setImage(File? value) {
    _image = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setWebImage(Uint8List? value) {
    _webImage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
