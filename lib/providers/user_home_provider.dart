import 'package:flutter/material.dart';

class UserHomeProvider extends ChangeNotifier {
  Map<String, dynamic> _selectedTown = {};
  String? _searchValue;
  bool _showPendingOnly = false;

  Map<String, dynamic> get selectedTown => _selectedTown;
  String? get searchValue => _searchValue;
  bool get showPendingOnly => _showPendingOnly;

  void setSelectedTown(Map<String, dynamic> value) {
    _selectedTown = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setSearchValue(String? value) {
    _searchValue = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setShoePendingOnly(bool value) {
    _showPendingOnly = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void reset() {
    _selectedTown = {};
    _searchValue = null;
    _showPendingOnly = false;
  }
}
