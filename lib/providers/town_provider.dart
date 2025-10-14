import 'package:flutter/material.dart';

class TownProvider extends ChangeNotifier {
  String? _query;
  bool _addButtonHover = false;
  bool _searchButtonHover = false;

  String? get query => _query;
  bool get addButtonHover => _addButtonHover;
  bool get searchButtonHover => _searchButtonHover;

  void setQuery(String? query) {
    _query = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setAddButtonHover(bool value) {
    _addButtonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setSearchButtonHover(bool value) {
    _searchButtonHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearQuery() {
    _query = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
