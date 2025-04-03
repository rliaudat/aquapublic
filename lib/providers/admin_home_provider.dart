import 'package:agua_med/_services/town_services.dart';
import 'package:agua_med/_services/user_services.dart';
import 'package:flutter/material.dart';

class AdminHomeProvider extends ChangeNotifier {
  String _townCount = '-';
  String _houseOwnerCount = '-';
  String _managerCount = '-';
  String _inspectorCount = '-';

  String get townCount => _townCount;
  String get houseOwnerCount => _houseOwnerCount;
  String get managerCount => _managerCount;
  String get inspectorCount => _inspectorCount;

  void loadData() async {
    var result = await Future.wait([
      TownServices.fetchAll(),
      UserServices.fetchByRole('HouseOwner'),
      UserServices.fetchByRole('Manager'),
      UserServices.fetchByRole('Inspector'),
    ]);

    _townCount = (result[0]).length.toString();
    _houseOwnerCount = (result[1]).length.toString();
    _managerCount = (result[2]).length.toString();
    _inspectorCount = (result[3]).length.toString();

    notifyListeners();
  }
}
