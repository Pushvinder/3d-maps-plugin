import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calculates the 2D screen offset (X, Y) for a 3D coordinate (latitude, longitude, altitude)
/// based on the current 3D map camera position and screen viewport size.
Offset? projectLatLngToScreen({
  required double markerLat,
  required double markerLng,
  required double cameraLat,
  required double cameraLng,
  required double cameraRange,
  required double headingDeg,
  required double tiltDeg,
  required Size screenSize,
}) {
  final dLatRad = (markerLat - cameraLat) * (math.pi / 180.0);
  final dLngRad = (markerLng - cameraLng) * (math.pi / 180.0);

  // Meters per degree approximation on Earth surface
  const metersPerDegreeLat = 111139.0;
  final metersPerDegreeLng = 111139.0 * math.cos(cameraLat * (math.pi / 180.0));

  final dyMeters = dLatRad * (180.0 / math.pi) * metersPerDegreeLat;
  final dxMeters = dLngRad * (180.0 / math.pi) * metersPerDegreeLng;

  // Heading rotation (camera orientation angle)
  final headingRad = headingDeg * (math.pi / 180.0);
  final rotatedX = dxMeters * math.cos(headingRad) - dyMeters * math.sin(headingRad);
  final rotatedY = dxMeters * math.sin(headingRad) + dyMeters * math.cos(headingRad);

  // Perspective scaling based on camera range (view distance in meters)
  final pixelsPerMeter = screenSize.height / (cameraRange * 0.85);

  final tiltRad = tiltDeg * (math.pi / 180.0);
  final projectedX = (screenSize.width / 2.0) + (rotatedX * pixelsPerMeter);
  final projectedY = (screenSize.height / 2.0) - (rotatedY * pixelsPerMeter * math.cos(tiltRad));

  // Hide markers that are far off-screen
  if (projectedX < -150 ||
      projectedX > screenSize.width + 150 ||
      projectedY < -150 ||
      projectedY > screenSize.height + 150) {
    return null;
  }

  return Offset(projectedX, projectedY);
}
