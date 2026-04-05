import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class EditProfileProvider extends ChangeNotifier {
  String _profileImageUrl = "";
  File? _selectedImage;
  Uint8List? _webImage;

  String get profileImageUrl => _profileImageUrl;
  File? get selectedImage => _selectedImage;
  Uint8List? get webImage => _webImage;

  void setProfileImageURL(String value) {
    _profileImageUrl = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setSelectedImage(File value) {
    _selectedImage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setWebImage(Uint8List value) {
    _webImage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
