import 'dart:io';

import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:flutter/material.dart';

class OwnerDetailProvider extends ChangeNotifier {
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

  void fetchTowns(AppUser currentUser) async {
    if (currentUser.role == 'Admin') {
      var listedTowns = await TownServices.fetchAllWithDelete();
      _towns = listedTowns.map((data) {
        return {'id': data.id, 'name': data.name};
      }).toList();
    } else if (currentUser.role == 'Manager') {
      _towns = currentUser.town == null
          ? []
          : [Map<String, dynamic>.from(currentUser.town)];
    } else if (currentUser.role == 'Inspector') {
      _towns = (currentUser.town as List? ?? [])
          .whereType<Map>()
          .map((town) => Map<String, dynamic>.from(town))
          .toList();
    } else {
      _towns = [];
    }
    notifyListeners();
  }

  void fetchHouses(String townID) async {
    var listedHouses = await HouseServices.fetchAllByTownWithDelete(townID);
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
    notifyListeners();
  }

  void setIsConfirmPasswordVisible(bool value) {
    _isConfirmPasswordVisible = value;
    notifyListeners();
  }

  void setProfileImage(File? value) {
    _profileImage = value;
    notifyListeners();
  }

  void setUpdateHover(bool value) {
    _updateHover = value;
    notifyListeners();
  }
}
