import 'package:flutter/material.dart';

class AdminInvoiceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _searchHover = false;

  bool get isLoading => _isLoading;
  bool get searchHover => _searchHover;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSearchHover(bool value) {
    _searchHover = value;
    notifyListeners();
  }
}
