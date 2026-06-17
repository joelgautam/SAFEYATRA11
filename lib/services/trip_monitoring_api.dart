import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_session.dart';
import 'live_location.dart';

class TripMonitoringApi {
  static Future<List<PredefinedRoute>> getSafeRoutes() async {
    final response = await http.get(
      Uri.parse('${AppSession.apiBaseUrl}/predefined-routes/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw StateError('Could not fetch safe routes.');
    }
    final List data = jsonDecode(response.body);
    return data.map((json) => PredefinedRoute.fromJson(json)).toList();
  }

  static Future<PassiveTripStart> startPassiveTrip({
    required String userId,
    required String startLabel,
    required String destinationLabel,
    LiveLocation? startLocation,
    LiveLocation? destinationLocation,
    String? predefinedRouteId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppSession.apiBaseUrl}/trips/start-passive/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'start_label': startLabel,
        'destination_label': destinationLabel,
        if (startLocation != null) 'start_lat': startLocation.latitude,
        if (startLocation != null) 'start_lng': startLocation.longitude,
        if (destinationLocation != null)
          'destination_lat': destinationLocation.latitude,
        if (destinationLocation != null)
          'destination_lng': destinationLocation.longitude,
        if (predefinedRouteId != null) 'predefined_route': predefinedRouteId,
        if (startLocation != null && destinationLocation != null)
          'planned_route': {
            'type': 'line',
            'points': [
              {
                'label': startLabel,
                'latitude': startLocation.latitude,
                'longitude': startLocation.longitude,
              },
              {
                'label': destinationLabel,
                'latitude': destinationLocation.latitude,
                'longitude': destinationLocation.longitude,
              },
            ],
          },
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw StateError(data['detail']?.toString() ?? 'Could not start trip.');
    }
    return PassiveTripStart.fromJson(data);
  }

  static Future<TripPingResult> sendPing({
    required String tripId,
    required LiveLocation location,
  }) async {
    final response = await http.post(
      Uri.parse('${AppSession.apiBaseUrl}/trips/$tripId/ping/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy_meters': location.accuracyMeters,
        'speed_mps': location.speedMps,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError(data['detail']?.toString() ?? 'Could not send ping.');
    }
    return TripPingResult.fromJson(data);
  }

  static Future<AlertResult> sendSos({
    required String tripId,
    LiveLocation? location,
  }) {
    return _sendAlertAction(
      tripId: tripId,
      action: 'sos',
      location: location,
    );
  }

  static Future<AlertResult> sendDeviationAlert({
    required String tripId,
    LiveLocation? location,
  }) {
    return _sendAlertAction(
      tripId: tripId,
      action: 'deviation-alert',
      location: location,
    );
  }

  static Future<void> markSafe(String tripId) async {
    final response = await http.post(
      Uri.parse('${AppSession.apiBaseUrl}/trips/$tripId/mark-safe/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw StateError(data['detail']?.toString() ?? 'Could not mark safe.');
    }
    await AppSession.clearActiveTripId();
  }

  static Future<AlertResult> _sendAlertAction({
    required String tripId,
    required String action,
    LiveLocation? location,
  }) async {
    final response = await http.post(
      Uri.parse('${AppSession.apiBaseUrl}/trips/$tripId/$action/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (location != null) 'latitude': location.latitude,
        if (location != null) 'longitude': location.longitude,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw StateError(data['detail']?.toString() ?? 'Could not send alert.');
    }
    return AlertResult.fromJson(data);
  }
}

class PassiveTripStart {
  final String tripId;
  final int guardiansNotified;

  const PassiveTripStart({
    required this.tripId,
    required this.guardiansNotified,
  });

  factory PassiveTripStart.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>;
    return PassiveTripStart(
      tripId: trip['id'].toString(),
      guardiansNotified: json['guardians_notified'] as int? ?? 0,
    );
  }
}

class TripPingResult {
  final bool deviationDetected;
  final String tripStatus;

  const TripPingResult({
    required this.deviationDetected,
    required this.tripStatus,
  });

  factory TripPingResult.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>;
    return TripPingResult(
      deviationDetected: json['deviation_detected'] == true,
      tripStatus: trip['status']?.toString() ?? '',
    );
  }
}

class AlertResult {
  final int recipientsNotified;

  const AlertResult({required this.recipientsNotified});

  factory AlertResult.fromJson(Map<String, dynamic> json) {
    return AlertResult(
      recipientsNotified: json['recipients_notified'] as int? ?? 0,
    );
  }
}

class PredefinedRoute {
  final String id;
  final String name;
  final String description;
  final List<LiveLocation> waypoints;

  const PredefinedRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
  });

  factory PredefinedRoute.fromJson(Map<String, dynamic> json) {
    final waypointsList = json['waypoints'] as List? ?? [];
    return PredefinedRoute(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      waypoints: waypointsList.map((w) {
        return LiveLocation(
          latitude: (w['lat'] as num).toDouble(),
          longitude: (w['lng'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}
