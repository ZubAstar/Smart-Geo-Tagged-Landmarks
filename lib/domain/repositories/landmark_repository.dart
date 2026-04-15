// lib/domain/repositories/landmark_repository.dart

import 'dart:io';
import '../../core/errors/app_exception.dart';
import '../../data/datasources/remote_datasource.dart';
import '../entities/landmark_entity.dart';
import '../entities/visit_entity.dart';

abstract class LandmarkRepository {
  Future<Result<List<LandmarkEntity>>> getLandmarks();

  Future<Result<VisitResult>> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
    required String landmarkName,
  });

  Future<Result<bool>> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File image,
  });

  Future<Result<bool>> deleteLandmark(int id);
  Future<Result<bool>> restoreLandmark(int id);
  Future<Result<List<VisitEntity>>> getVisitHistory();
  Future<int> getPendingVisitCount();
  Future<void> syncQueuedVisits();
}
