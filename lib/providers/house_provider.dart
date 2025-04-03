import 'package:flutter/material.dart';

class HouseProvider extends ChangeNotifier {
  String? _query;
  bool _addButtonHover = false;
  bool _searchButtonHover = false;

  String? get query => _query;
  bool get addButtonHover => _addButtonHover;
  bool get searchButtonHover => _searchButtonHover;

  void setQuery(String? query) {
    _query = query;
    notifyListeners();
  }

  void setAddButtonHover(bool value) {
    _addButtonHover = value;
    notifyListeners();
  }

  void setSearchButtonHover(bool value) {
    _searchButtonHover = value;
    notifyListeners();
  }

  void clearQuery() {
    _query = null;
    notifyListeners();
  }
}
