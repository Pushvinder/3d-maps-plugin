import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'map_3d_mode.dart';
import 'place_location.dart';

typedef CameraMoveCallback = void Function(
    double lat, double lng, double range, double heading, double tilt);

class ThreeDMapController {
  final MethodChannel channel;
  CameraMoveCallback? onCameraMoveListener;

  ThreeDMapController(this.channel);

  /// Fly the 3D map camera to specified coordinates.
  Future<void> flyTo({
    required double lat,
    required double lng,
    double alt = 500.0,
    double heading = 0.0,
    double tilt = 60.0,
    double range = 1500.0,
    int durationMs = 3000,
  }) async {
    try {
      if (onCameraMoveListener != null) {
        onCameraMoveListener!(lat, lng, range, heading, tilt);
      }
      await channel.invokeMethod('flyTo', {
        'lat': lat,
        'lng': lng,
        'alt': alt,
        'heading': heading,
        'tilt': tilt,
        'range': range,
        'durationMs': durationMs,
      });
    } catch (e) {
      debugPrint('ThreeDMapController.flyTo error: $e');
    }
  }

  /// Fly camera to a predefined [PlaceLocation].
  Future<void> flyToPlace(PlaceLocation place, {int durationMs = 3000}) async {
    await flyTo(
      lat: place.lat,
      lng: place.lng,
      alt: place.alt,
      heading: place.heading,
      tilt: place.tilt,
      range: place.range,
      durationMs: durationMs,
    );
  }

  /// Animate camera tilt angle (e.g. 0.0 for 2D top-down view or 63.0 for 3D perspective view).
  Future<void> setTilt(double tilt, {int durationMs = 1500}) async {
    try {
      await channel.invokeMethod('setTilt', {
        'tilt': tilt,
        'durationMs': durationMs,
      });
    } catch (e) {
      debugPrint('ThreeDMapController.setTilt error: $e');
    }
  }

  /// Toggle between 2D (0.0° tilt) and 3D (63.0° tilt) map perspective.
  Future<void> toggle2D3D({required bool is2D, int durationMs = 1500}) async {
    await setTilt(is2D ? 0.0 : 63.0, durationMs: durationMs);
  }

  /// Switch between Normal 2D Roadmap Google Map (roadmap mode at 0.0° tilt) and 3D Photorealistic Map (hybrid mode at 63.0° tilt).
  Future<void> setNormalMapMode(bool isNormalMap, {int durationMs = 1500}) async {
    await setMapMode(isNormalMap ? Map3DMode.roadmap : Map3DMode.hybrid);
    await setTilt(isNormalMap ? 0.0 : 63.0, durationMs: durationMs);
  }

  /// Search for a location or landmark by query name.
  Future<PlaceLocation?> searchLocation(String query) async {
    try {
      final map = await channel.invokeMethod<Map>('searchLocation', {
        'query': query,
      });
      if (map != null) {
        return PlaceLocation.fromMap(map);
      }
    } catch (e) {
      debugPrint('ThreeDMapController.searchLocation error: $e');
    }
    return null;
  }

  /// Set Map 3D Mode ([Map3DMode.hybrid], [Map3DMode.satellite], or [Map3DMode.roadmap]).
  Future<void> setMapMode(Map3DMode mode) async {
    try {
      await channel.invokeMethod('setMapMode', {
        'mapMode': mode.value,
      });
    } catch (e) {
      debugPrint('ThreeDMapController.setMapMode error: $e');
    }
  }

  /// Add a marker to the 3D map.
  Future<void> addMarker(Map<String, dynamic> markerData) async {
    try {
      await channel.invokeMethod('addMarker', markerData);
    } catch (e) {
      debugPrint('ThreeDMapController.addMarker error: $e');
    }
  }

  /// Remove a marker by ID.
  Future<void> removeMarker(String id) async {
    try {
      await channel.invokeMethod('removeMarker', {'id': id});
    } catch (e) {
      debugPrint('ThreeDMapController.removeMarker error: $e');
    }
  }

  /// Clear all markers from the 3D map.
  Future<void> clearMarkers() async {
    try {
      await channel.invokeMethod('clearMarkers');
    } catch (e) {
      debugPrint('ThreeDMapController.clearMarkers error: $e');
    }
  }
}
