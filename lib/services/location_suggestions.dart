import 'dart:math' as math;

import 'live_location.dart';

class LocationSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const LocationSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  String get label => '$name, $address';
}

const kathmanduLocationSuggestions = <LocationSuggestion>[
  LocationSuggestion(
    name: 'Current location',
    address: 'Using GPS',
    latitude: 0,
    longitude: 0,
  ),
  LocationSuggestion(
    name: 'Thamel',
    address: 'Kathmandu, Nepal',
    latitude: 27.7153,
    longitude: 85.3123,
  ),
  LocationSuggestion(
    name: 'Patan Durbar Square',
    address: 'Mangal Bazaar, Lalitpur',
    latitude: 27.6726,
    longitude: 85.3241,
  ),
  LocationSuggestion(
    name: 'Boudhanath Stupa',
    address: 'Boudha, Kathmandu',
    latitude: 27.7215,
    longitude: 85.3620,
  ),
  LocationSuggestion(
    name: 'Swayambhunath (Monkey Temple)',
    address: 'Swayambhu, Kathmandu',
    latitude: 27.7149,
    longitude: 85.2903,
  ),
  LocationSuggestion(
    name: 'Kathmandu Durbar Square',
    address: 'Basantapur, Kathmandu',
    latitude: 27.7042,
    longitude: 85.3066,
  ),
  LocationSuggestion(
    name: 'Kings College Nepal',
    address: 'Babar Mahal, Kathmandu',
    latitude: 27.6949,
    longitude: 85.3225,
  ),
  LocationSuggestion(
    name: 'Tribhuvan International Airport',
    address: 'Ring Road, Kathmandu',
    latitude: 27.6966,
    longitude: 85.3591,
  ),
  LocationSuggestion(
    name: 'Koteshwor Junction',
    address: 'Koteshwor, Kathmandu',
    latitude: 27.6782,
    longitude: 85.3492,
  ),
  LocationSuggestion(
    name: 'Kalanki Bus Stop',
    address: 'Kalanki, Kathmandu',
    latitude: 27.6937,
    longitude: 85.2818,
  ),
  LocationSuggestion(
    name: 'Lainchaur Ground',
    address: 'Lazimpat, Kathmandu',
    latitude: 27.7175,
    longitude: 85.3168,
  ),
  LocationSuggestion(
    name: 'Maitidevi Temple',
    address: 'Maitidevi, Kathmandu',
    latitude: 27.7048,
    longitude: 85.3337,
  ),
  LocationSuggestion(
    name: 'Civil Mall',
    address: 'Sundhara, Kathmandu',
    latitude: 27.7001,
    longitude: 85.3121,
  ),
];

List<LocationSuggestion> searchLocationSuggestions(
  String query, {
  LiveLocation? origin,
}) {
  final normalized = query.trim().toLowerCase();
  final results = normalized.isEmpty
      ? kathmanduLocationSuggestions.where((l) => l.name != 'Current location').toList()
      : kathmanduLocationSuggestions.where((location) {
          return location.name.toLowerCase().contains(normalized) ||
              location.address.toLowerCase().contains(normalized);
        }).toList();

  if (origin == null) return results.take(10).toList();

  final sorted = [...results]..sort((a, b) {
      final aDistance = distanceInKm(
        origin.latitude,
        origin.longitude,
        a.latitude,
        a.longitude,
      );
      final bDistance = distanceInKm(
        origin.latitude,
        origin.longitude,
        b.latitude,
        b.longitude,
      );
      return aDistance.compareTo(bDistance);
    });
  return sorted.take(8).toList();
}

double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _radians(lat2 - lat1);
  final dLng = _radians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180.0;
