import 'package:flutter/material.dart';
import 'package:three_d_map/three_d_map.dart';

void main() {
  runApp(const MaterialApp(
    home: ThreeDMapExampleScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ThreeDMapExampleScreen extends StatefulWidget {
  const ThreeDMapExampleScreen({super.key});

  @override
  State<ThreeDMapExampleScreen> createState() => _ThreeDMapExampleScreenState();
}

class _ThreeDMapExampleScreenState extends State<ThreeDMapExampleScreen> {
  ThreeDMapController? _mapController;
  MapMarker? _selectedMarker;
  final List<MapMarker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initUserMarkers();
  }

  void _initUserMarkers() {
    final userProfiles = [
      MapMarker(
        id: 'user_1',
        latitude: 38.5540,
        longitude: -107.6804,
        altitude: 2450.0,
        title: 'Alice Johnson',
        snippet: 'North Peak • Travel Blogger',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.pinkAccent,
      ),
      MapMarker(
        id: 'user_2',
        latitude: 38.5340,
        longitude: -107.6604,
        altitude: 2400.0,
        title: 'Bob Smith',
        snippet: 'South Ridge • Software Engineer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.blueAccent,
      ),
      MapMarker(
        id: 'user_3',
        latitude: 38.5600,
        longitude: -107.6500,
        altitude: 2500.0,
        title: 'Priya Sharma',
        snippet: 'East Valley • Architect',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.amber,
      ),
      MapMarker(
        id: 'user_4',
        latitude: 38.5200,
        longitude: -107.6900,
        altitude: 2380.0,
        title: 'Kenji Sato',
        snippet: 'West Canyon • Photographer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.purpleAccent,
      ),
      MapMarker(
        id: 'user_5',
        latitude: 38.5440,
        longitude: -107.6704,
        altitude: 2427.6,
        title: 'Carlos Garcia',
        snippet: 'Center Overlook • Adventurer',
        imageUrl: 'https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png',
        imageSize: 60,
        imageRadius: 30,
        color: Colors.teal,
      ),
    ];

    _markers.addAll(userProfiles);
  }

  void _onMapCreated(ThreeDMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _handleMarkerTap(MapMarker marker) {
    setState(() {
      _selectedMarker = marker;
    });

    // Fly camera in 3D to user location
    _mapController?.flyTo(
      lat: marker.latitude,
      lng: marker.longitude,
      alt: marker.altitude > 0 ? marker.altitude + 250 : 600.0,
      heading: 0.0,
      tilt: 60.0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D User Map - 5 User Profiles'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Camera',
            onPressed: () {
              setState(() {
                _selectedMarker = null;
              });
              _mapController?.flyTo(
                lat: 38.544012,
                lng: -107.670428,
                alt: 2427.6,
                heading: 310.0,
                tilt: 63.0,
                range: 8266.0,
                durationMs: 2000,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Native 3D Map with Geographic Projection Overlay
          ThreeDMapViewWidget(
            initialLat: 38.544012,
            initialLng: -107.670428,
            initialAlt: 2427.6,
            heading: 310.0,
            tilt: 63.0,
            range: 8266.0,
            mapMode: Map3DMode.hybrid,
            showSearchBar: false,
            markers: _markers,
            onMapCreated: _onMapCreated,
            onMarkerTap: _handleMarkerTap,
            onMapReady: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('3D Map Ready! Tap a user pic above to fly to their location.')),
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

          // 2. Top Row: Quick User Selector Chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _markers.map((marker) {
                  final isSelected = _selectedMarker?.id == marker.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundImage: marker.imageUrl != null
                            ? NetworkImage(marker.imageUrl!)
                            : null,
                        child: marker.imageUrl == null
                            ? Icon(Icons.person, size: 14, color: marker.color)
                            : null,
                      ),
                      label: Text(marker.title ?? marker.id),
                      backgroundColor: isSelected ? Colors.indigo : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      elevation: 4,
                      onPressed: () => _handleMarkerTap(marker),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. Bottom Detail Card for Selected User Profile
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
