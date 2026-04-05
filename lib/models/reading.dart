// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Reading {
  final String id;
  final double amount;
  final int consumptionDays;
  final Timestamp date;
  final String houseId;
  final String inspectorId;
  final String meterImageURL;
  final double previousReading;
  final double previousUnits;
  final double reading;
  final String townId;
  final double units;
  final List<String> comment;
  final bool isDelete;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  Reading({
    required this.id,
    required this.amount,
    required this.consumptionDays,
    required this.date,
    required this.houseId,
    required this.inspectorId,
    required this.meterImageURL,
    required this.previousReading,
    required this.previousUnits,
    required this.reading,
    required this.townId,
    required this.units,
    required this.comment,
    required this.isDelete,
    required this.createdAt,
    required this.updatedAt,
  });

  Reading copyWith({
    String? id,
    double? amount,
    int? consumptionDays,
    Timestamp? date,
    String? houseId,
    String? inspectorId,
    String? meterImageURL,
    double? previousReading,
    double? previousUnits,
    double? reading,
    String? townId,
    double? units,
    List<String>? comment,
    bool? isDelete,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Reading(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      consumptionDays: consumptionDays ?? this.consumptionDays,
      date: date ?? this.date,
      houseId: houseId ?? this.houseId,
      inspectorId: inspectorId ?? this.inspectorId,
      meterImageURL: meterImageURL ?? this.meterImageURL,
      previousReading: previousReading ?? this.previousReading,
      previousUnits: previousUnits ?? this.previousUnits,
      reading: reading ?? this.reading,
      townId: townId ?? this.townId,
      units: units ?? this.units,
      comment: comment ?? this.comment,
      isDelete: isDelete ?? this.isDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'amount': amount,
      'consumptionDays': consumptionDays,
      'date': date,
      'houseId': houseId,
      'inspectorId': inspectorId,
      'meterImageURL': meterImageURL,
      'previousReading': previousReading,
      'previousUnits': previousUnits,
      'reading': reading,
      'townId': townId,
      'units': units,
      'comment': comment,
      'isDelete': isDelete,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'] as String,
      amount: map['amount'] as double,
      consumptionDays: map['consumptionDays'] as int,
      date: map['date'],
      houseId: map['houseId'] as String,
      inspectorId: map['inspectorId'] as String,
      meterImageURL: map['meterImageURL'] as String,
      previousReading: map['previousReading'] as double,
      previousUnits: map['previousUnits'] as double,
      reading: map['reading'] as double,
      townId: map['townId'] as String,
      units: map['units'] as double,
      comment: List<String>.from((map['comment'] as List<String>)),
      isDelete: map['isDelete'] as bool,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  factory Reading.fromDoc(DocumentSnapshot snapshot) {
    return Reading(
      id: snapshot['id'] as String,
      amount: snapshot['amount'] as double,
      consumptionDays: snapshot['consumptionDays'] as int,
      date: snapshot['date'],
      houseId: snapshot['houseId'] as String,
      inspectorId: snapshot['inspectorId'] as String,
      meterImageURL: snapshot['meterImageURL'] as String,
      previousReading: snapshot['previousReading'] as double,
      previousUnits: snapshot['previousUnits'] as double,
      reading: snapshot['reading'] as double,
      townId: snapshot['townId'] as String,
      units: snapshot['units'] as double,
      comment: List<String>.from((snapshot['comment'] as List<String>)),
      isDelete: snapshot['isDelete'] as bool,
      createdAt: snapshot['createdAt'],
      updatedAt: snapshot['updatedAt'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Reading.fromJson(String source) =>
      Reading.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Reading(id: $id, amount: $amount, consumptionDays: $consumptionDays, date: $date, houseId: $houseId, inspectorId: $inspectorId, meterImageURL: $meterImageURL, previousReading: $previousReading, previousUnits: $previousUnits, reading: $reading, townId: $townId, units: $units, comment: $comment, isDelete: $isDelete, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant Reading other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.amount == amount &&
        other.consumptionDays == consumptionDays &&
        other.date == date &&
        other.houseId == houseId &&
        other.inspectorId == inspectorId &&
        other.meterImageURL == meterImageURL &&
        other.previousReading == previousReading &&
        other.previousUnits == previousUnits &&
        other.reading == reading &&
        other.townId == townId &&
        other.units == units &&
        listEquals(other.comment, comment) &&
        other.isDelete == isDelete &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        consumptionDays.hashCode ^
        date.hashCode ^
        houseId.hashCode ^
        inspectorId.hashCode ^
        meterImageURL.hashCode ^
        previousReading.hashCode ^
        previousUnits.hashCode ^
        reading.hashCode ^
        townId.hashCode ^
        units.hashCode ^
        comment.hashCode ^
        isDelete.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
