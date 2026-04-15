// lib/data/models/visit_model.dart

import '../../domain/entities/visit_entity.dart';

class VisitModel extends VisitEntity {
  const VisitModel({
    required super.id,
    required super.landmarkId,
    required super.landmarkName,
    required super.visitTime,
    required super.distance,
    required super.synced,
    super.userLat,
    super.userLon,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id']?.toString() ?? '',
      landmarkId: int.tryParse(json['landmark_id']?.toString() ?? '0') ?? 0,
      landmarkName: json['landmark_name']?.toString() ?? json['title']?.toString() ?? '',
      visitTime: json['visit_time'] != null
          ? DateTime.tryParse(json['visit_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
      synced: true,
    );
  }

  factory VisitModel.fromDb(Map<String, dynamic> row) {
    return VisitModel(
      id: row['id'].toString(),
      landmarkId: row['landmark_id'] as int,
      landmarkName: row['landmark_name'] as String,
      visitTime: DateTime.fromMillisecondsSinceEpoch(row['visit_time'] as int),
      distance: row['distance'] as double,
      synced: (row['synced'] as int) == 1,
      userLat: row['user_lat'] as double?,
      userLon: row['user_lon'] as double?,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'landmark_id': landmarkId,
      'landmark_name': landmarkName,
      'visit_time': visitTime.millisecondsSinceEpoch,
      'distance': distance,
      'synced': synced ? 1 : 0,
      'user_lat': userLat,
      'user_lon': userLon,
    };
  }
}

class QueuedVisit {
  final int? dbId;
  final int landmarkId;
  final double userLat;
  final double userLon;
  final DateTime queuedAt;

  const QueuedVisit({
    this.dbId,
    required this.landmarkId,
    required this.userLat,
    required this.userLon,
    required this.queuedAt,
  });

  factory QueuedVisit.fromDb(Map<String, dynamic> row) {
    return QueuedVisit(
      dbId: row['id'] as int?,
      landmarkId: row['landmark_id'] as int,
      userLat: row['user_lat'] as double,
      userLon: row['user_lon'] as double,
      queuedAt: DateTime.fromMillisecondsSinceEpoch(row['queued_at'] as int),
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'landmark_id': landmarkId,
      'user_lat': userLat,
      'user_lon': userLon,
      'queued_at': queuedAt.millisecondsSinceEpoch,
    };
  }
}
