import 'package:flutter/material.dart';

class LoginProvider extends ChangeNotifier {
  bool _isPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;

  void setIsPasswordVisible(bool value) {
    _isPasswordVisible = value;
    notifyListeners();
  }
}
