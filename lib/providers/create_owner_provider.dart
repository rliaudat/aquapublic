import 'dart:io';

import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:flutter/material.dart';

class CreateOwnerProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _towns = [];
  List<Map<String, dynamic>> _houses = [];

  dynamic _selectedTown;
  dynamic _selectedHouse;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _profileImage;
  bool _updateHover = false;

  List<Map<String, dynamic>> get towns => _towns;
  List<Map<String, dynamic>> get houses => _houses;

  dynamic get selectedTown => _selectedTown;
  dynamic get selectedHouse => _selectedHouse;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  File? get profileImage => _profileImage;
  bool get updateHover => _updateHover;

  void fetchTowns(AppUser user) async {
    var listedTowns = await TownServices.fetchAll();
    if (user.role == 'Admin') {
      _towns = listedTowns.map((data) {
        return {'id': data.id, 'name': data.name};
      }).toList();
      _selectedTown = towns.first;
      fetchHouses(_selectedTown['id']);
    } else if (user.role == 'Manager') {
      towns.add(user.town);
      if (towns.isNotEmpty) {
        _selectedTown = towns.first;
        fetchHouses(_selectedTown['id']);
      }
    } else if (user.role == 'Inspector') {
      towns.addAll(user.town);
      if (towns.isNotEmpty) {
        _selectedTown = towns.first;
        fetchHouses(_selectedTown['id']);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void fetchHouses(String townID) async {
    var listedHouses = await HouseServices.fetchAllByTown(townID);
    _houses = listedHouses.map((data) {
      return {'id': data.id, 'name': data.name};
    }).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setTown(dynamic value) {
    _selectedTown = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setHouse(dynamic value) {
    _selectedHouse = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setIsPasswordVisible(bool value) {
    _isPasswordVisible = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setIsConfirmPasswordVisible(bool value) {
    _isConfirmPasswordVisible = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setProfileImage(File? value) {
    _profileImage = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setUpdateHover(bool value) {
    _updateHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
