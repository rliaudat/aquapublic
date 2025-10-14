import 'package:flutter/material.dart';

class AdminInvoiceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _searchHover = false;

  bool get isLoading => _isLoading;
  bool get searchHover => _searchHover;

  void setIsLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setSearchHover(bool value) {
    _searchHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
