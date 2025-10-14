import 'package:flutter/material.dart';

class SearchHouseBillProvider extends ChangeNotifier {
  String _searchValue = "";
  int _currentPage = 0;
  int _rowsPerPage = 10;
  int? _totalRows;
  int? _totalPages;

  String get searchValue => _searchValue;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  int? get totalPages => _totalPages;

  void setSearchValue(String value) {
    _searchValue = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setCurrentPage(int value) {
    _currentPage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setRowsPerPage(int value) {
    _rowsPerPage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setTotalRowAndPage(int value) {
    _totalRows = value;
    _totalPages = ((_totalRows ?? 0) / _rowsPerPage).ceil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
