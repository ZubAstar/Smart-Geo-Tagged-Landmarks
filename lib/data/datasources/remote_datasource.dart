// lib/data/datasources/remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/landmark_model.dart';
import '../models/visit_model.dart';

class RemoteDataSource {
  final DioClient _client;

  RemoteDataSource(this._client);

  Future<List<LandmarkModel>> fetchLandmarks() async {
    final response = await _client.get(AppConstants.actionGetLandmarks);
    final body = response.data;

    List<dynamic> items;
    if (body is List) {
      items = body;
    } else if (body is Map && body['data'] != null) {
      items = body['data'] as List;
    } else if (body is Map && body['landmarks'] != null) {
      items = body['landmarks'] as List;
    } else {
      throw const ServerException('Unexpected response format');
    }

    return items
        .map((e) => LandmarkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VisitResult> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
  }) async {
    final response = await _client.post(
      AppConstants.actionVisitLandmark,
      {
        'landmark_id': landmarkId,
        'user_lat': userLat,
        'user_lon': userLon,
      },
      options: Options(contentType: 'application/json'),
    );

    final body = response.data as Map<String, dynamic>;
    return VisitResult(
      success: body['success'] == true || body['status'] == 'success',
      message: body['message']?.toString() ?? 'Visit recorded',
      distance: _parseDouble(body['distance'] ?? body['dist']),
    );
  }

  Future<bool> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'landmark_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    final response = await _client.post(
      AppConstants.actionCreateLandmark,
      formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data;
    if (body is Map) {
      return body['success'] == true || body['status'] == 'success';
    }
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> deleteLandmark(int id) async {
    final response = await _client.post(
      AppConstants.actionDeleteLandmark,
      {'landmark_id': id},
      options: Options(contentType: 'application/json'),
    );
    final body = response.data;
    if (body is Map) {
      return body['success'] == true || body['status'] == 'success';
    }
    return response.statusCode == 200;
  }

  Future<bool> restoreLandmark(int id) async {
    final response = await _client.post(
      AppConstants.actionRestoreLandmark,
      {'landmark_id': id},
      options: Options(contentType: 'application/json'),
    );
    final body = response.data;
    if (body is Map) {
      return body['success'] == true || body['status'] == 'success';
    }
    return response.statusCode == 200;
  }

  Future<List<VisitModel>> fetchVisitHistory() async {
    final response = await _client.get(AppConstants.actionGetVisits);
    final body = response.data;
    List<dynamic> items = [];
    if (body is List) {
      items = body;
    } else if (body is Map) {
      items = (body['data'] ?? body['visits'] ?? []) as List;
    }
    return items
        .map((e) => VisitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class VisitResult {
  final bool success;
  final String message;
  final double distance;

  const VisitResult({
    required this.success,
    required this.message,
    required this.distance,
  });
}
