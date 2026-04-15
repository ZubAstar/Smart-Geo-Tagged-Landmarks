// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'https://labs.anontech.info/cse489/exm3/api.php';
  static const String apiKey = '22301407';

  // API Actions
  static const String actionGetLandmarks = 'get_landmarks';
  static const String actionVisitLandmark = 'visit_landmark';
  static const String actionCreateLandmark = 'create_landmark';
  static const String actionDeleteLandmark = 'delete_landmark';
  static const String actionRestoreLandmark = 'restore_landmark';
  static const String actionGetVisits = 'get_visits';

  // Map
  static const double bangladeshLat = 23.6850;
  static const double bangladeshLon = 90.3563;
  static const double defaultZoom = 7.5;
  static const double detailZoom = 14.0;

  // DB
  static const String dbName = 'geo_landmarks.db';
  static const int dbVersion = 2;
  static const String tableLandmarks = 'landmarks';
  static const String tableVisitQueue = 'visit_queue';
  static const String tableVisitHistory = 'visit_history';

  // Score thresholds for marker color
  static const double scoreLow = 3.0;
  static const double scoreMid = 6.5;
}
