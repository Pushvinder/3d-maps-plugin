# flutter_3d_map

A high-performance, cross-platform Flutter plugin for embedding photorealistic 3D maps on **Android** (powered by Google Maps 3D Jetpack Compose SDK) and **iOS** (powered by Apple MapKit 3D Elevation & Flyover).

[![pub package](https://img.shields.io/pub/v/flutter_3d_map.svg)](https://pub.dev/packages/flutter_3d_map)
[![Flutter](https://img.shields.io/badge/Flutter->=3.3.0-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Screenshots

| Android (Google Maps 3D) | iOS (Apple MapKit 3D Elevation) |
| :---: | :---: |
| <img src="https://raw.githubusercontent.com/Pushvinder/3d-maps-plugin/refs/heads/main/doc/screenshots/map_3d_demo_android.png?token=GHSAT0AAAAAAEJDCPCQQU3JNBDDU5AJY2WE2WFODFA" width="360" alt="Android 3D Map View"/> | <img src="https://raw.githubusercontent.com/Pushvinder/3d-maps-plugin/refs/heads/main/doc/screenshots/map_3d_demo_ios.png?token=GHSAT0AAAAAAEJDCPCQNZNZIWZACOWRT2Z42WFOD3Q" width="360" alt="iOS 3D Map View"/> |

---

## Features

- 🏙️ **Photorealistic 3D Map View**: Full 3D terrain elevation, 3D photorealistic buildings, and camera control across altitude, tilt, heading, and range.
- 📍 **Custom Remote Image Markers**: Render markers with custom remote image URLs, circular clipping radius, custom sizes, title, snippet, and tap callbacks.
- 📹 **Continuous Camera Movement Listener**: Receive real-time `onCameraMove` callbacks delivering continuous `(lat, lng, range, heading, tilt)` during live drag, pan, pinch, zoom, and rotation gestures on both Android and iOS.
- ✈️ **Smooth `flyTo` Camera Animations**: Animate the camera smoothly to any latitude, longitude, altitude, heading, tilt, and range with custom animation durations.
- 🎨 **Dynamic Map Modes**: Easily switch between **Hybrid**, **Satellite**, and **Roadmap** modes at runtime.
- 🔄 **2D / 3D Perspective Toggle**: Instantly toggle between 2D top-down view (0° tilt) and 3D photorealistic perspective (60° tilt).
- 🔍 **Geocoding & Landmark Search**: Search for predefined global landmarks (e.g., Eiffel Tower, Taj Mahal, Burj Khalifa) or reverse-geocode location queries via `searchLocation`.

---

## Platform Setup

### Android Setup

1. Ensure your `android/app/build.gradle` has `minSdkVersion` set to **21** or higher.
2. Obtain a Google Maps API Key from the [Google Cloud Console](https://console.cloud.google.com/) with **Google Maps 3D / Maps SDK** enabled.
3. Add your API Key inside `android/app/src/main/AndroidManifest.xml` under `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
    </application>
</manifest>
```

### iOS Setup

1. Ensure your `ios/Podfile` sets platform deployment target to **iOS 13.0** or higher:

```ruby
platform :ios, '13.0'
```

2. Apple MapKit is natively built into iOS — **no extra API key is required for iOS**!

---

## Getting Started

Add `flutter_3d_map` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_3d_map: ^0.0.1
```

Run `flutter pub get` in your terminal.

---

## Basic Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_3d_map/flutter_3d_map.dart';

void main() {
  runApp(const MaterialApp(
    home: Map3DScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class Map3DScreen extends StatefulWidget {
  const Map3DScreen({super.key});

  @override
  State<Map3DScreen> createState() => _Map3DScreenState();
}

class _Map3DScreenState extends State<Map3DScreen> {
  ThreeDMapController? _mapController;

  final List<MapMarker> _markers = [
    MapMarker(
      id: 'profile_1',
      latitude: 38.5540,
      longitude: -107.6804,
      altitude: 2450.0,
      title: 'Alice Johnson',
      snippet: 'Travel Blogger',
      imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      imageSize: 60,
      imageRadius: 30,
      color: Colors.pinkAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Map View'),
        backgroundColor: Colors.indigo,
      ),
      body: ThreeDMapViewWidget(
        initialLat: 38.544012,
        initialLng: -107.670428,
        initialAlt: 2427.6,
        heading: 310.0,
        tilt: 63.0,
        range: 8266.0,
        mapMode: Map3DMode.hybrid,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onCameraMove: (lat, lng, range, heading, tilt) {
          debugPrint('Camera position: ($lat, $lng) range: $range, tilt: $tilt, heading: $heading');
        },
        onMarkerTap: (marker) {
          debugPrint('Tapped marker: ${marker.title}');
          _mapController?.flyTo(
            lat: marker.latitude,
            lng: marker.longitude,
            alt: marker.altitude + 200,
            tilt: 60.0,
            range: 1200.0,
            durationMs: 2000,
          );
        },
        onMapClick: (lat, lng, alt, placeId) {
          debugPrint('Map clicked at: ($lat, $lng, $alt)');
        },
      ),
    );
  }
}
```

---

## API Reference

### `ThreeDMapViewWidget`

The primary widget used to render the 3D map platform view.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `initialLat` | `double` | `38.544012` | Initial camera latitude coordinate. |
| `initialLng` | `double` | `-107.670428` | Initial camera longitude coordinate. |
| `initialAlt` | `double` | `2427.6` | Initial camera altitude in meters. |
| `heading` | `double` | `310.0` | Initial camera heading angle (0.0° to 360.0°). |
| `tilt` | `double` | `63.0` | Initial camera tilt pitch angle (0.0° for 2D, 60.0° for 3D). |
| `range` | `double` | `8266.0` | Initial camera range distance in meters. |
| `mapMode` | `Map3DMode` | `Map3DMode.hybrid` | Active map mode (`hybrid`, `satellite`, `roadmap`). |
| `markers` | `List<MapMarker>` | `[]` | List of custom image markers to display. |
| `onMapCreated` | `MapCreatedCallback?` | `null` | Callback invoked when `ThreeDMapController` is ready. |
| `onMapReady` | `VoidCallback?` | `null` | Callback invoked when 3D tiles and map view finish loading. |
| `onCameraMove` | `CameraMoveCallback?` | `null` | Continuous callback during camera drag/zoom `(lat, lng, range, heading, tilt)`. |
| `onMarkerTap` | `MarkerTapCallback?` | `null` | Callback invoked when a user taps a marker on the map. |
| `onMapClick` | `MapClickCallback?` | `null` | Callback invoked when a user clicks an empty location on the map. |
| `onError` | `MapErrorCallback?` | `null` | Callback invoked if an error occurs during initialization. |

---

### `ThreeDMapController`

Controller returned by `onMapCreated` to programmatically control the 3D map.

| Method | Parameters | Description |
|---|---|---|
| `flyTo()` | `lat`, `lng`, `alt`, `heading`, `tilt`, `range`, `durationMs` | Smoothly animates camera to target coordinates and angle. |
| `flyToPlace()` | `PlaceLocation place`, `durationMs` | Animates camera to a predefined `PlaceLocation`. |
| `setTilt()` | `tilt`, `durationMs` | Animates camera tilt/pitch angle. |
| `setNormalMapMode()` | `isNormalMap`, `durationMs` | Switches between 2D roadmap mode and 3D photorealistic mode. |
| `setMapMode()` | `Map3DMode mode` | Changes map mode (`hybrid`, `satellite`, `roadmap`). |
| `addMarker()` | `Map<String, dynamic> markerData` | Dynamically adds a new marker to the 3D map. |
| `removeMarker()` | `String id` | Removes a marker by its ID. |
| `clearMarkers()` | `Future<void>` | Clears all markers from the map. |
| `searchLocation()` | `String query` | Searches for landmark or location by name query. |

---

### `MapMarker`

Data model defining custom image markers.

```dart
MapMarker(
  id: 'user_1',
  latitude: 38.5540,
  longitude: -107.6804,
  altitude: 2450.0,
  title: 'Alice Johnson',
  snippet: 'Travel Blogger',
  imageUrl: 'https://example.com/avatar.png',
  imageSize: 60.0,      // Image width/height in dp
  imageRadius: 30.0,    // Corner clipping radius for circular avatars
  color: Colors.indigo,
)
```

---

## Supported Platforms

- **Android**: API 21+ (Google Maps 3D SDK)
- **iOS**: iOS 13.0+ (Apple MapKit 3D Elevation)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
