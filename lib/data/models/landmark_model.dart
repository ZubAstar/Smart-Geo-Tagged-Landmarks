// lib/data/models/landmark_model.dart

import '../../domain/entities/landmark_entity.dart';

class LandmarkModel extends LandmarkEntity {
  const LandmarkModel({
    required super.id,
    required super.title,
    required super.lat,
    required super.lon,
    super.image,
    required super.score,
    required super.visitCount,
    required super.avgDistance,
    required super.isDeleted,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) {
    return LandmarkModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
      image: json['image']?.toString(),
      score: _parseDouble(json['score']),
      visitCount: _parseInt(json['visit_count']),
      avgDistance: _parseDouble(json['avg_distance']),
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == '1' || json['is_deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
      'score': score,
      'visit_count': visitCount,
      'avg_distance': avgDistance,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory LandmarkModel.fromDb(Map<String, dynamic> row) {
    return LandmarkModel(
      id: row['id'] as int,
      title: row['title'] as String,
      lat: row['lat'] as double,
      lon: row['lon'] as double,
      image: row['image'] as String?,
      score: row['score'] as double,
      visitCount: row['visit_count'] as int,
      avgDistance: row['avg_distance'] as double,
      isDeleted: (row['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
      'score': score,
      'visit_count': visitCount,
      'avg_distance': avgDistance,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  LandmarkModel copyWithDeleted(bool deleted) {
    return LandmarkModel(
      id: id,
      title: title,
      lat: lat,
      lon: lon,
      image: image,
      score: score,
      visitCount: visitCount,
      avgDistance: avgDistance,
      isDeleted: deleted,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
