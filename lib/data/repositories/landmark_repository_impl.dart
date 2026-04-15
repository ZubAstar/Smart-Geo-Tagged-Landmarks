// lib/data/repositories/landmark_repository_impl.dart

import 'dart:io';
import '../../core/errors/app_exception.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/landmark_entity.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/repositories/landmark_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/remote_datasource.dart';
import '../models/landmark_model.dart';
import '../models/visit_model.dart';

class LandmarkRepositoryImpl implements LandmarkRepository {
  final RemoteDataSource _remote;
  final LocalDatabase _local;
  final NetworkInfo _network;

  LandmarkRepositoryImpl({
    required RemoteDataSource remote,
    required LocalDatabase local,
    required NetworkInfo network,
  })  : _remote = remote,
        _local = local,
        _network = network;

  @override
  Future<Result<List<LandmarkEntity>>> getLandmarks() async {
    if (await _network.isConnected) {
      try {
        final landmarks = await _remote.fetchLandmarks();
        await _local.cacheLandmarks(landmarks);
        return Result.success(
            landmarks.where((l) => !l.isDeleted).toList());
      } on AppException catch (e) {
        return _fallbackToCache(e);
      } catch (e) {
        return _fallbackToCache(ServerException(e.toString()));
      }
    } else {
      return _fallbackToCache(const NetworkException());
    }
  }

  Future<Result<List<LandmarkEntity>>> _fallbackToCache(AppException original) async {
    try {
      final cached = await _local.getCachedLandmarks();
      if (cached.isNotEmpty) {
        return Result.success(cached.where((l) => !l.isDeleted).toList());
      }
      return Result.failure(original);
    } catch (_) {
      return Result.failure(original);
    }
  }

  @override
  Future<Result<VisitResult>> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
    required String landmarkName,
  }) async {
    if (await _network.isConnected) {
      try {
        final result = await _remote.visitLandmark(
          landmarkId: landmarkId,
          userLat: userLat,
          userLon: userLon,
        );

        // Save to history
        final visit = VisitModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          landmarkId: landmarkId,
          landmarkName: landmarkName,
          visitTime: DateTime.now(),
          distance: result.distance,
          synced: true,
          userLat: userLat,
          userLon: userLon,
        );
        await _local.saveVisitHistory(visit);
        return Result.success(result);
      } on AppException catch (e) {
        return Result.failure(e);
      }
    } else {
      // Queue for later
      await _local.enqueueVisit(QueuedVisit(
        landmarkId: landmarkId,
        userLat: userLat,
        userLon: userLon,
        queuedAt: DateTime.now(),
      ));

      // Save unsynced to history
      final visit = VisitModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        landmarkId: landmarkId,
        landmarkName: landmarkName,
        visitTime: DateTime.now(),
        distance: 0,
        synced: false,
        userLat: userLat,
        userLon: userLon,
      );
      await _local.saveVisitHistory(visit);
      return Result.success(VisitResult(
        success: true,
        message: 'Visit queued — will sync when online',
        distance: 0,
      ));
    }
  }

  @override
  Future<Result<bool>> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File image,
  }) async {
    if (!await _network.isConnected) {
      return Result.failure(const NetworkException('Internet required to add landmarks'));
    }
    try {
      final ok = await _remote.createLandmark(
        title: title, lat: lat, lon: lon, imageFile: image,
      );
      return Result.success(ok);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<bool>> deleteLandmark(int id) async {
    // Optimistic local update
    await _local.softDeleteLandmark(id);
    if (await _network.isConnected) {
      try {
        final ok = await _remote.deleteLandmark(id);
        if (!ok) await _local.restoreLandmark(id);
        return Result.success(ok);
      } on AppException catch (_) {
        await _local.restoreLandmark(id);
        return Result.failure(const NetworkException('Failed to delete remotely'));
      }
    }
    return Result.success(true); // local delete succeeded
  }

  @override
  Future<Result<bool>> restoreLandmark(int id) async {
    await _local.restoreLandmark(id);
    if (await _network.isConnected) {
      try {
        final ok = await _remote.restoreLandmark(id);
        return Result.success(ok);
      } on AppException catch (e) {
        return Result.failure(e);
      }
    }
    return Result.success(true);
  }

  @override
  Future<Result<List<VisitEntity>>> getVisitHistory() async {
    try {
      final history = await _local.getVisitHistory();
      return Result.success(history);
    } catch (e) {
      return Result.failure(CacheException(e.toString()));
    }
  }

  @override
  Future<int> getPendingVisitCount() => _local.getPendingVisitCount();

  @override
  Future<void> syncQueuedVisits() async {
    if (!await _network.isConnected) return;
    final queued = await _local.getPendingVisits();
    for (final visit in queued) {
      try {
        final result = await _remote.visitLandmark(
          landmarkId: visit.landmarkId,
          userLat: visit.userLat,
          userLon: visit.userLon,
        );
        if (result.success && visit.dbId != null) {
          await _local.removeQueuedVisit(visit.dbId!);
        }
      } catch (_) {
        // Keep in queue, try next time
      }
    }
  }
}
