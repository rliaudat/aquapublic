// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String isoCode;
  final String dialCode;
  final String role;
  final String status;
  final String? profileImageURL;
  final String? fcmToken;
  final String? platform;
  final bool isDelete;
  final dynamic town;
  final dynamic house;
  final String encryptedPassword;
  final String iv;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isoCode,
    required this.dialCode,
    required this.role,
    required this.status,
    this.profileImageURL,
    this.fcmToken,
    this.platform,
    required this.isDelete,
    required this.town,
    required this.house,
    required this.encryptedPassword,
    required this.iv,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? isoCode,
    String? dialCode,
    String? role,
    String? status,
    String? profileImageURL,
    String? fcmToken,
    String? platform,
    bool? isDelete,
    dynamic town,
    Map<String, dynamic>? house,
    String? encryptedPassword,
    String? iv,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isoCode: isoCode ?? this.isoCode,
      dialCode: dialCode ?? this.dialCode,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImageURL: profileImageURL ?? this.profileImageURL,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      isDelete: isDelete ?? this.isDelete,
      town: town ?? this.town,
      house: house ?? this.house,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      iv: iv ?? this.iv,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isoCode': isoCode,
      'dialCode': dialCode,
      'role': role,
      'status': status,
      'profileImageURL': profileImageURL,
      'fcmToken': fcmToken,
      'platform': platform,
      'isDelete': isDelete,
      'town': town,
      'house': house,
      'encryptedPassword': encryptedPassword,
      'iv': iv,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String,
      isoCode: map['isoCode'] as String,
      dialCode: map['dialCode'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
      profileImageURL: map['profileImageURL'] != null
          ? map['profileImageURL'] as String
          : null,
      fcmToken: map['fcmToken'] != null ? map['fcmToken'] as String : null,
      platform: map['platform'] as String?,
      isDelete: map['isDelete'] as bool,
      town: map['town'] as dynamic,
      house: map['house'] as dynamic,
      encryptedPassword: map['encryptedPassword'] as String,
      iv: map['iv'] as String,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot snapshot) {
    return AppUser(
      uid: snapshot['uid'] as String,
      firstName: snapshot['firstName'] as String,
      lastName: snapshot['lastName'] as String,
      email: snapshot['email'] as String,
      phoneNumber: snapshot['phoneNumber'] as String,
      isoCode: snapshot['isoCode'] as String,
      dialCode: snapshot['dialCode'] as String,
      role: snapshot['role'] as String,
      status: snapshot['status'] as String,
      profileImageURL: snapshot['profileImageURL'] != null
          ? snapshot['profileImageURL'] as String
          : null,
      fcmToken:
          snapshot['fcmToken'] != null ? snapshot['fcmToken'] as String : null,
      platform: snapshot['platform'] as String?,
      isDelete: snapshot['isDelete'] as bool,
      town: snapshot['town'] as dynamic,
      house: snapshot['house'] as dynamic,
      encryptedPassword: snapshot['encryptedPassword'] as String,
      iv: snapshot['iv'] as String,
      createdAt: snapshot['createdAt'],
      updatedAt: snapshot['updatedAt'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppUser(uid: $uid, firstName: $firstName, lastName: $lastName, email: $email, phoneNumber: $phoneNumber, isoCode: $isoCode, dialCode: $dialCode, role: $role, status: $status, profileImageURL: $profileImageURL, fcmToken: $fcmToken, platform: $platform, isDelete: $isDelete, town: $town, house: $house, encryptedPassword: $encryptedPassword, iv: $iv, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant AppUser other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.isoCode == isoCode &&
        other.dialCode == dialCode &&
        other.role == role &&
        other.status == status &&
        other.profileImageURL == profileImageURL &&
        other.fcmToken == fcmToken &&
        other.platform == platform &&
        other.isDelete == isDelete &&
        other.town == town &&
        mapEquals(other.house, house) &&
        other.encryptedPassword == encryptedPassword &&
        other.iv == iv &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        isoCode.hashCode ^
        dialCode.hashCode ^
        role.hashCode ^
        status.hashCode ^
        profileImageURL.hashCode ^
        fcmToken.hashCode ^
        platform.hashCode ^
        isDelete.hashCode ^
        town.hashCode ^
        house.hashCode ^
        encryptedPassword.hashCode ^
        iv.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
