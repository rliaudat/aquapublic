import 'dart:io';

import 'package:agua_med/_services/house_services.dart';
import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/models/town.dart';
import 'package:flutter/material.dart';

class SignUpProvider extends ChangeNotifier {
  List<Town> _towns = [];
  List<House> _houses = [];

  dynamic _selectedTown;
  dynamic _selectedHouse;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _profileImage;

  List<Town> get towns => _towns;
  List<House> get houses => _houses;

  dynamic get selectedTown => _selectedTown;
  dynamic get selectedHouse => _selectedHouse;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  File? get profileImage => _profileImage;

  void fetchTowns() async {
    _towns = await TownServices.fetchAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void fetchHouses(String townID) async {
    _houses = await HouseServices.fetchAllByTown(townID);
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

  void reset() {
    _towns = [];
    _houses = [];

    _selectedTown = null;
    _selectedHouse = null;
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _profileImage = null;
  }
}
