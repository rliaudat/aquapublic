import 'package:flutter/material.dart';

class AllUserProvider extends ChangeNotifier {
  String _searchQuery = "";
  bool _addHover = false;

  String get searchQuery => _searchQuery;
  bool get addHover => _addHover;

  void setSearchQuery(String value) {
    _searchQuery = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setAddHover(bool value) {
    _addHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
