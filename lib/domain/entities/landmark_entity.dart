// lib/domain/entities/landmark_entity.dart

class LandmarkEntity {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String? image;
  final double score;
  final int visitCount;
  final double avgDistance;
  final bool isDeleted;

  const LandmarkEntity({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
    required this.score,
    required this.visitCount,
    required this.avgDistance,
    this.isDeleted = false,
  });

  String get scoreLabel {
    if (score >= 8) return 'Iconic';
    if (score >= 6) return 'Popular';
    if (score >= 4) return 'Notable';
    return 'Hidden Gem';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LandmarkEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
