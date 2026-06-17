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
    throw UnsupportedError('Live location is only configured for web here.');
  }
}
