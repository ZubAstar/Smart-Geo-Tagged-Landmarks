// lib/domain/entities/visit_entity.dart

class VisitEntity {
  final String id;
  final int landmarkId;
  final String landmarkName;
  final DateTime visitTime;
  final double distance;
  final bool synced;
  final double? userLat;
  final double? userLon;

  const VisitEntity({
    required this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.visitTime,
    required this.distance,
    required this.synced,
    this.userLat,
    this.userLon,
  });
}
