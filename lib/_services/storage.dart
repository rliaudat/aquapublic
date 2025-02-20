import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

FlutterSecureStorage storage = const FlutterSecureStorage();

class Storage {
  static Future setLogin(data) async {
    await storage.write(key: 'user', value: jsonEncode(data));
    return true;
  }

  static Future<dynamic> getLogin() async {
    dynamic value = await storage.read(key: 'user');
    if (value != null) {
      return jsonDecode(value);
    } else {
      return false;
    }
  }


  static Future<bool> logout() async {
    await storage.deleteAll();
    return true;
  }
}

