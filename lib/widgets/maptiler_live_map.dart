import 'dart:math' as math;

import 'package:flutter/material.dart';

class MapTilerLiveMap extends StatelessWidget {
  static const apiKey = '0IZLTuHSzUvZD1hB3rDO';

  final double centerLatitude;
  final double centerLongitude;
  final int zoom;
  final double? darkTintOpacity;
  final Widget? overlay;

  const MapTilerLiveMap({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.zoom = 14,
    this.darkTintOpacity,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (apiKey.isEmpty)
              Image.asset(
                'assets/kathmandu_map.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFD8E8C8),
                ),
              )
            else
              _TileGrid(
                centerLatitude: centerLatitude,
                centerLongitude: centerLongitude,
                zoom: zoom,
                width: width,
                height: height,
                apiKey: apiKey,
              ),
            if (darkTintOpacity != null)
              Container(color: const Color(0xFF2D1B69).withOpacity(darkTintOpacity!)),
            if (overlay != null) overlay!,
          ],
        );
      },
    );
  }
}

class _TileGrid extends StatelessWidget {
  static const _tileSize = 256.0;

  final double centerLatitude;
  final double centerLongitude;
  final int zoom;
  final double width;
  final double height;
  final String apiKey;

  const _TileGrid({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.zoom,
    required this.width,
    required this.height,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    final center = _latLngToWorld(centerLatitude, centerLongitude, zoom);
    final startX = ((center.dx - width / 2) / _tileSize).floor() - 1;
    final endX = ((center.dx + width / 2) / _tileSize).ceil() + 1;
    final startY = ((center.dy - height / 2) / _tileSize).floor() - 1;
    final endY = ((center.dy + height / 2) / _tileSize).ceil() + 1;
    final maxTile = math.pow(2, zoom).toInt();
    final tiles = <Widget>[];

    for (var x = startX; x <= endX; x++) {
      for (var y = startY; y <= endY; y++) {
        if (y < 0 || y >= maxTile) continue;
        final wrappedX = ((x % maxTile) + maxTile) % maxTile;
        final left = x * _tileSize - center.dx + width / 2;
        final top = y * _tileSize - center.dy + height / 2;
        tiles.add(
          Positioned(
            left: left,
            top: top,
            width: _tileSize,
            height: _tileSize,
            child: Image.network(
              'https://api.maptiler.com/maps/streets-v2/256/$zoom/$wrappedX/$y.png?key=$apiKey',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFEDEBE4),
              ),
            ),
          ),
        );
      }
    }

    return Stack(clipBehavior: Clip.hardEdge, children: tiles);
  }

  Offset _latLngToWorld(double lat, double lng, int zoom) {
    final scale = math.pow(2, zoom) * _tileSize;
    final x = (lng + 180.0) / 360.0 * scale;
    final sinLat = math.sin(lat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final y = (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }
}
