import 'dart:html' as html;

class LiveLocation {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedMps;

  const LiveLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.speedMps,
  });
}

class LiveLocationService {
  Future<LiveLocation> current() async {
    final geolocation = html.window.navigator.geolocation;
    final position = await geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 8),
      maximumAge: const Duration(seconds: 2),
    );
    final coords = position.coords;
    if (coords == null) {
      throw StateError('Browser did not return location coordinates.');
    }
    return LiveLocation(
      latitude: coords.latitude?.toDouble() ?? 27.7172,
      longitude: coords.longitude?.toDouble() ?? 85.324,
      accuracyMeters: coords.accuracy?.toDouble(),
      speedMps: coords.speed?.toDouble(),
    );
  }
}
