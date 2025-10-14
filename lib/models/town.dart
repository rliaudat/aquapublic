import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Town {
  final String id;
  final String name;
  final double unitPrice;
  final bool isDelete;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  Town({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.isDelete,
    required this.createdAt,
    required this.updatedAt,
  });

  Town copyWith({
    String? id,
    String? name,
    double? unitPrice,
    bool? isDelete,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Town(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      isDelete: isDelete ?? this.isDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'isDelete': isDelete,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Town.fromMap(Map<String, dynamic> map) {
    return Town(
      id: map['id'] as String,
      name: map['name'] as String,
      unitPrice: map['unitPrice'] as double,
      isDelete: map['isDelete'] as bool,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  factory Town.fromDoc(DocumentSnapshot snapshot) {
    return Town(
      id: snapshot['id'] as String,
      name: snapshot['name'] as String,
      unitPrice: double.parse(snapshot['unitPrice'].toString()),
      isDelete: snapshot['isDelete'] as bool,
      createdAt: snapshot['createdAt'],
      updatedAt: snapshot['updatedAt'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Town.fromJson(String source) =>
      Town.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Town(id: $id, name: $name, unitPrice: $unitPrice, isDelete: $isDelete, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant Town other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.unitPrice == unitPrice &&
        other.isDelete == isDelete &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        unitPrice.hashCode ^
        isDelete.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
