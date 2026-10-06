import 'package:flutter/material.dart';
import 'package:flutter_3d_map/flutter_3d_map.dart';

/// Entry point for the 3D Map Example application.
void main() {
  runApp(const MaterialApp(
    home: ThreeDMapExampleScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

/// Main example screen demonstrating photorealistic 3D map features:
/// - Interactive custom image markers for user profiles
/// - Continuous real-time camera movement tracking (Lat, Lng, Range, Tilt, Heading)
/// - Perspective toggling between 2D top-down view and 3D 60° view
/// - Dynamic map mode selection (Hybrid, Satellite, Roadmap)
/// - Marker tap fly-to animations and profile detail cards
class ThreeDMapExampleScreen extends StatefulWidget {
  const ThreeDMapExampleScreen({super.key});

  @override
  State<ThreeDMapExampleScreen> createState() => _ThreeDMapExampleScreenState();
}

class _ThreeDMapExampleScreenState extends State<ThreeDMapExampleScreen> {
  // ===========================================================================
  // Step 1: State Variables & Map Controller Setup
  // ===========================================================================

  /// Controller used to invoke native 3D map camera animations and marker methods.
  ThreeDMapController? _mapController;

  /// Currently selected user marker profile for displaying detail overlay.
  MapMarker? _selectedMarker;

  /// List of active user profile markers on the 3D map.
  final List<MapMarker> _markers = [];

  /// Flag tracking whether current view perspective is 2D (0.0° tilt) or 3D (60.0° tilt).
  bool _is2DMode = false;

  /// Active 3D map configuration mode (Hybrid, Satellite, or Roadmap).
  Map3DMode _currentMapMode = Map3DMode.hybrid;

  // Real-time camera state updated continuously via onCameraMove callback
  double? _cameraLat;
  double? _cameraLng;
  double? _cameraRange;
  double? _cameraHeading;
  double? _cameraTilt;

  // ===========================================================================
  // Step 2: Lifecycle & User Marker Initialization
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initUserMarkers();
  }

  /// Initializes default user profiles around Eiffel Tower with custom coordinates, circular image styling, and colors.
  void _initUserMarkers() {
    final userProfiles = [
      MapMarker(
        id: 'user_1',
        latitude: 48.8584,
        longitude: 2.2945,
        altitude: 350.0,
        title: 'Alice Johnson',
        snippet: 'Eiffel Tower Summit • Travel Blogger',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.pinkAccent,
      ),
      MapMarker(
        id: 'user_2',
        latitude: 48.8558,
        longitude: 2.2980,
        altitude: 50.0,
        title: 'Bob Smith',
        snippet: 'Champ de Mars Park • Software Engineer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.blueAccent,
      ),
      MapMarker(
        id: 'user_3',
        latitude: 48.8616,
        longitude: 2.2893,
        altitude: 75.0,
        title: 'Priya Sharma',
        snippet: 'Trocadéro Overlook • Architect',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.amber,
      ),
      MapMarker(
        id: 'user_4',
        latitude: 48.8598,
        longitude: 2.2930,
        altitude: 40.0,
        title: 'Kenji Sato',
        snippet: 'Seine River Quay • Photographer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.purpleAccent,
      ),
      MapMarker(
        id: 'user_5',
        latitude: 48.8570,
        longitude: 2.2910,
        altitude: 60.0,
        title: 'Carlos Garcia',
        snippet: 'Gustave Eiffel Overlook • Adventurer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.teal,
      ),
    ];

    _markers.addAll(userProfiles);
  }

  // ===========================================================================
  // Step 3: Map Event Handlers & Interactions
  // ===========================================================================

  /// Callback invoked when the native platform view controller is instantiated.
  void _onMapCreated(ThreeDMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  /// Handles marker tap: selects user marker and flies camera smoothly to location.
  void _handleMarkerTap(MapMarker marker) {
    setState(() {
      _selectedMarker = marker;
    });

    // Animate camera flight in 3D or 2D mode to the tapped marker
    _mapController?.flyTo(
      lat: marker.latitude,
      lng: marker.longitude,
      alt: marker.altitude > 0 ? marker.altitude + 250 : 600.0,
      heading: 0.0,
      tilt: _is2DMode ? 0.0 : 60.0,
      range: 1200.0,
      durationMs: 2500,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing Profile: ${marker.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Adds a new custom user profile marker dynamically at clicked map coordinates.
  void _addCustomUserMarker(double lat, double lng, double alt) {
    final newIndex = _markers.length + 1;
    final newMarker = MapMarker(
      id: 'user_$newIndex',
      latitude: lat,
      longitude: lng,
      altitude: alt,
      title: 'User #$newIndex',
      snippet: 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      imageSize: 60,
      imageRadius: 30,
      color: Colors.deepOrangeAccent,
    );

    setState(() {
      _markers.add(newMarker);
    });

    _mapController?.addMarker(newMarker.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added User #$newIndex at (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})')),
    );
  }

  // ===========================================================================
  // Step 4: Perspective & Map Mode Toggles
  // ===========================================================================

  /// Toggles camera perspective between 2D (0.0° tilt) and 3D (60.0° tilt).
  void _toggle2D3DMode() {
    setState(() {
      _is2DMode = !_is2DMode;
    });
    _mapController?.setNormalMapMode(_is2DMode);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_is2DMode ? 'Switched to Normal 2D Google Map' : 'Switched to 3D Photorealistic Map'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Switches active map mode (Hybrid, Satellite, or Roadmap).
  void _changeMapMode(Map3DMode mode) {
    setState(() {
      _currentMapMode = mode;
    });
    _mapController?.setMapMode(mode);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map Mode: ${mode.name.toUpperCase()}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ===========================================================================
  // Step 5: User Interface Construction
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 3D Map'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Popup menu for switching Map Modes (Hybrid, Satellite, Roadmap)
          PopupMenuButton<Map3DMode>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Map Mode',
            onSelected: _changeMapMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Map3DMode.hybrid,
                child: Row(
                  children: [
                    Icon(Icons.layers, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Hybrid Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Map3DMode.satellite,
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Satellite Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Map3DMode.roadmap,
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Roadmap Mode'),
                  ],
                ),
              ),
            ],
          ),

          // 2D / 3D Mode Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _is2DMode ? Colors.amber : Colors.indigo.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              onPressed: _toggle2D3DMode,
              icon: Icon(
                _is2DMode ? Icons.map : Icons.view_in_ar,
                size: 18,
              ),
              label: Text(
                _is2DMode ? '2D' : '3D',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),

          // Camera Reset Action Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Camera',
            onPressed: () {
              setState(() {
                _selectedMarker = null;
                _is2DMode = false;
              });
              _mapController?.setNormalMapMode(false);
              _mapController?.flyTo(
                lat: 48.8584,
                lng: 2.2945,
                alt: 324.0,
                heading: 140.0,
                tilt: 65.0,
                range: 1000.0,
                durationMs: 2000,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // Layer 1: Native Photorealistic 3D Map View
          // -------------------------------------------------------------------
          ThreeDMapViewWidget(
            initialLat: 48.8584,
            initialLng: 2.2945,
            initialAlt: 324.0,
            heading: 140.0,
            tilt: 65.0,
            range: 1000.0,
            mapMode: _currentMapMode,
            showSearchBar: false,
            markers: _markers,
            onMapCreated: _onMapCreated,
            onMarkerTap: _handleMarkerTap,
            onCameraMove: (lat, lng, range, heading, tilt) {
              setState(() {
                _cameraLat = lat;
                _cameraLng = lng;
                _cameraRange = range;
                _cameraHeading = heading;
                _cameraTilt = tilt;
              });
            },
            onMapReady: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('3D Map Ready! Tap 2D/3D button or chips to select user profiles.')),
                );
              }
            },
            onMapClick: (lat, lng, alt, placeId) {
              _addCustomUserMarker(lat, lng, alt);
            },
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('3D Map Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),

          // -------------------------------------------------------------------
          // Layer 2: Real-time Camera Movement Status Overlay Bar
          // -------------------------------------------------------------------
          if (_cameraLat != null && _cameraLng != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lat: ${_cameraLat!.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lng: ${_cameraLng!.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Range: ${_cameraRange?.toStringAsFixed(0)}m',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tilt: ${_cameraTilt?.toStringAsFixed(0)}°',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Heading: ${_cameraHeading?.toStringAsFixed(0)}°',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // -------------------------------------------------------------------
          // Layer 3: Bottom Detail Card for Selected User Profile
          // -------------------------------------------------------------------
          if (_selectedMarker != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedMarker!.color,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: _selectedMarker!.imageUrl != null
                                  ? NetworkImage(_selectedMarker!.imageUrl!)
                                  : null,
                              child: _selectedMarker!.imageUrl == null
                                  ? Icon(Icons.person, size: 28, color: _selectedMarker!.color)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedMarker!.title ?? _selectedMarker!.id,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedMarker!.snippet != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedMarker!.snippet!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedMarker = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Coords: (${_selectedMarker!.latitude.toStringAsFixed(3)}, ${_selectedMarker!.longitude.toStringAsFixed(3)})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _handleMarkerTap(_selectedMarker!),
                            icon: const Icon(Icons.flight_takeoff, size: 16),
                            label: const Text('Fly To User'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
