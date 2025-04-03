import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class House {
  final String id;
  final String name;
  final String townID;
  final bool isDelete;
  final Map<String, dynamic>? lastReading;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  House({
    required this.id,
    required this.name,
    required this.townID,
    required this.isDelete,
    this.lastReading,
    required this.createdAt,
    required this.updatedAt,
  });

  House copyWith({
    String? id,
    String? name,
    String? townID,
    bool? isDelete,
    Map<String, dynamic>? lastReading,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return House(
      id: id ?? this.id,
      name: name ?? this.name,
      townID: townID ?? this.townID,
      isDelete: isDelete ?? this.isDelete,
      lastReading: lastReading ?? this.lastReading,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'townID': townID,
      'isDelete': isDelete,
      'lastReading': lastReading,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] as String,
      name: map['name'] as String,
      townID: map['townID'] as String,
      isDelete: map['isDelete'] as bool,
      lastReading: map['lastReading'] != null
          ? Map<String, dynamic>.from(
              (map['lastReading'] as Map<String, dynamic>))
          : null,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  factory House.fromDoc(DocumentSnapshot snapshot) {
    return House(
      id: snapshot['id'] as String,
      name: snapshot['name'] as String,
      townID: snapshot['townID'] as String,
      isDelete: snapshot['isDelete'] as bool,
      lastReading: snapshot['lastReading'] != null
          ? Map<String, dynamic>.from(
              (snapshot['lastReading'] as Map<String, dynamic>),
            )
          : null,
      createdAt: snapshot['createdAt'],
      updatedAt: snapshot['updatedAt'],
    );
  }

  String toJson() => json.encode(toMap());

  factory House.fromJson(String source) =>
      House.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'House(id: $id, name: $name, townID: $townID, isDelete: $isDelete, lastReading: $lastReading, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant House other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.townID == townID &&
        other.isDelete == isDelete &&
        mapEquals(other.lastReading, lastReading) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        townID.hashCode ^
        isDelete.hashCode ^
        lastReading.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
