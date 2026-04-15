// lib/presentation/providers/providers.dart

import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_info.dart';
import '../../data/datasources/local_database.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/landmark_repository_impl.dart';
import '../../domain/entities/landmark_entity.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/repositories/landmark_repository.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final localDbProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(Connectivity()),
);

final remoteDataSourceProvider = Provider<RemoteDataSource>(
  (ref) => RemoteDataSource(ref.read(dioClientProvider)),
);

final landmarkRepositoryProvider = Provider<LandmarkRepository>(
  (ref) => LandmarkRepositoryImpl(
    remote: ref.read(remoteDataSourceProvider),
    local: ref.read(localDbProvider),
    network: ref.read(networkInfoProvider),
  ),
);

// ─── Connectivity Stream ─────────────────────────────────────────────────────

final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.read(networkInfoProvider).onConnectivityChanged;
});

// ─── Filter/Sort State ───────────────────────────────────────────────────────

class LandmarkFilter {
  final double minScore;
  final SortOrder sortOrder;
  final bool showDeleted;

  const LandmarkFilter({
    this.minScore = 0.0,
    this.sortOrder = SortOrder.scoreDesc,
    this.showDeleted = false,
  });

  LandmarkFilter copyWith({double? minScore, SortOrder? sortOrder, bool? showDeleted}) {
    return LandmarkFilter(
      minScore: minScore ?? this.minScore,
      sortOrder: sortOrder ?? this.sortOrder,
      showDeleted: showDeleted ?? this.showDeleted,
    );
  }
}

enum SortOrder { scoreDesc, scoreAsc, nameAsc, visitCountDesc }

final landmarkFilterProvider = StateProvider<LandmarkFilter>(
  (ref) => const LandmarkFilter(),
);

// ─── Landmark State ───────────────────────────────────────────────────────────

class LandmarkState {
  final List<LandmarkEntity> landmarks;
  final bool isLoading;
  final String? error;
  final bool fromCache;

  const LandmarkState({
    this.landmarks = const [],
    this.isLoading = false,
    this.error,
    this.fromCache = false,
  });

  LandmarkState copyWith({
    List<LandmarkEntity>? landmarks,
    bool? isLoading,
    String? error,
    bool? fromCache,
    bool clearError = false,
  }) {
    return LandmarkState(
      landmarks: landmarks ?? this.landmarks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class LandmarkNotifier extends StateNotifier<LandmarkState> {
  final LandmarkRepository _repo;

  LandmarkNotifier(this._repo) : super(const LandmarkState()) {
    loadLandmarks();
  }

  Future<void> loadLandmarks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getLandmarks();
    result.fold(
      onSuccess: (data) => state = state.copyWith(
        landmarks: data ?? [],
        isLoading: false,
      ),
      onFailure: (err) => state = state.copyWith(
        isLoading: false,
        error: err.message,
      ),
    );
  }

  Future<String> visitLandmark(int id, String name) async {
    Position pos;
    try {
      pos = await _determinePosition();
    } catch (e) {
      return 'Could not get location: $e';
    }

    final result = await _repo.visitLandmark(
      landmarkId: id,
      userLat: pos.latitude,
      userLon: pos.longitude,
      landmarkName: name,
    );

    return result.fold(
      onSuccess: (r) =>
          r!.success ? '${r.message} — ${r.distance.toStringAsFixed(1)} km away' : r.message,
      onFailure: (e) => e.message,
    );
  }

  Future<String> deleteLandmark(int id) async {
    final result = await _repo.deleteLandmark(id);
    if (result.isSuccess) {
      state = state.copyWith(
        landmarks: state.landmarks.where((l) => l.id != id).toList(),
      );
      return 'Landmark removed';
    }
    return result.error!.message;
  }

  Future<String> restoreLandmark(int id) async {
    final result = await _repo.restoreLandmark(id);
    return result.fold(
      onSuccess: (_) => 'Landmark restored',
      onFailure: (e) => e.message,
    );
  }

  Future<String> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File image,
  }) async {
    final result = await _repo.createLandmark(
      title: title, lat: lat, lon: lon, image: image,
    );
    if (result.isSuccess) await loadLandmarks();
    return result.fold(
      onSuccess: (_) => 'Landmark added successfully!',
      onFailure: (e) => e.message,
    );
  }

  Future<void> syncQueuedVisits() => _repo.syncQueuedVisits();
  Future<int> pendingCount() => _repo.getPendingVisitCount();

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationException('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission permanently denied');
    }
    // Fixed for geolocator 12.0.0
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

final landmarkProvider =
    StateNotifierProvider<LandmarkNotifier, LandmarkState>(
  (ref) => LandmarkNotifier(ref.read(landmarkRepositoryProvider)),
);

final filteredLandmarksProvider = Provider<List<LandmarkEntity>>((ref) {
  final state = ref.watch(landmarkProvider);
  final filter = ref.watch(landmarkFilterProvider);

  var list = state.landmarks
      .where((l) => l.score >= filter.minScore)
      .toList();

  switch (filter.sortOrder) {
    case SortOrder.scoreDesc:
      list.sort((a, b) => b.score.compareTo(a.score));
      break;
    case SortOrder.scoreAsc:
      list.sort((a, b) => a.score.compareTo(b.score));
      break;
    case SortOrder.nameAsc:
      list.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOrder.visitCountDesc:
      list.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      break;
  }
  return list;
});

// ─── Visit History ───────────────────────────────────────────────────────────

final visitHistoryProvider =
    FutureProvider<List<VisitEntity>>((ref) async {
  final repo = ref.read(landmarkRepositoryProvider);
  final result = await repo.getVisitHistory();
  return result.fold(onSuccess: (d) => d ?? [], onFailure: (_) => []);
});

// ─── Current Location ─────────────────────────────────────────────────────────

final currentLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    bool svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return null;
    // Fixed for geolocator 12.0.0
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (_) {
    return null;
  }
});
