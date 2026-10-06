## 1.0.4

* Updated `README.md` image links to use direct raw GitHub URLs for instant rendering on pub.dev and GitHub.

## 1.0.3

* Updated documentation and image relative paths for pub.dev asset rendering.

## 1.0.2

* Fixed screenshot image paths in `README.md` to use package relative paths for pub.dev rendering.

## 1.0.1

* Added screenshot previews in `README.md` and `pubspec.yaml` for Android and iOS 3D Map views.

## 1.0.0

* Initial release of `flutter_3d_map` Flutter plugin.
* Added Photorealistic 3D map rendering for Android (Google Maps 3D Jetpack Compose SDK) and iOS (Apple MapKit 3D Elevation & Flyover).
* Added custom remote image markers with circular radius clipping, custom size, and tap callbacks.
* Added continuous real-time `onCameraMove` callback for drag, pan, pinch, zoom, and tilt gestures.
* Added `flyTo` camera animation with customizable duration, altitude, tilt, heading, and range.
* Added dynamic map mode switching (`hybrid`, `satellite`, `roadmap`).
* Added 2D / 3D perspective toggle support.
* Added landmark location search and reverse geocoding via `searchLocation`.
