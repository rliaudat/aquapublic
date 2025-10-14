import 'package:agua_med/_services/town_services.dart';
import 'package:flutter/material.dart';

class UserRegistrationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _searchHover = false;
  String _searchQuery = "";
  Map<String, dynamic> _selectedTown = {};
  List _towns = [];

  bool get isLoading => _isLoading;
  bool get searchHover => _searchHover;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get selectedTown => _selectedTown;
  List get towns => _towns;

  void loadTowns(String role, Map? managerTown) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    _towns = [];
    if (role == 'Admin') {
      await TownServices.fetchAll().then((data) {
        _towns = data.map((doc) {
          return {
            'id': doc.id,
            'name': doc.name,
          };
        }).toList();
        _selectedTown = _towns.first;
      });
    } else {
      _towns.add(managerTown);
      if (_towns.isNotEmpty) {
        _selectedTown = _towns.first;
      }
    }
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setTown(Map<String, dynamic> value) {
    _selectedTown = value;
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

  void setSearchQuery(String value) {
    _searchQuery = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
