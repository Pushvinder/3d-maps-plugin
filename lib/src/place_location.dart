class PlaceLocation {
  final String name;
  final double lat;
  final double lng;
  final double alt;
  final double heading;
  final double tilt;
  final double range;

  const PlaceLocation({
    required this.name,
    required this.lat,
    required this.lng,
    this.alt = 500.0,
    this.heading = 0.0,
    this.tilt = 60.0,
    this.range = 1500.0,
  });

  factory PlaceLocation.fromMap(Map<dynamic, dynamic> map) {
    return PlaceLocation(
      name: map['name'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      alt: (map['alt'] as num?)?.toDouble() ?? 500.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      tilt: (map['tilt'] as num?)?.toDouble() ?? 60.0,
      range: (map['range'] as num?)?.toDouble() ?? 1500.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'alt': alt,
      'heading': heading,
      'tilt': tilt,
      'range': range,
    };
  }
}

/// Predefined list of iconic landmarks around the world.
const List<PlaceLocation> predefinedLandmarks = [
  PlaceLocation(
    name: "Eiffel Tower",
    lat: 48.8584,
    lng: 2.2945,
    alt: 300.0,
    heading: 45.0,
    tilt: 65.0,
    range: 600.0,
  ),
  PlaceLocation(
    name: "Mt. Everest",
    lat: 27.9881,
    lng: 86.9250,
    alt: 8848.0,
    heading: 180.0,
    tilt: 70.0,
    range: 12000.0,
  ),
  PlaceLocation(
    name: "Grand Canyon",
    lat: 36.0544,
    lng: -112.1401,
    alt: 2100.0,
    heading: 300.0,
    tilt: 60.0,
    range: 5000.0,
  ),
  PlaceLocation(
    name: "Statue of Liberty",
    lat: 40.6892,
    lng: -74.0445,
    alt: 100.0,
    heading: 15.0,
    tilt: 60.0,
    range: 400.0,
  ),
  PlaceLocation(
    name: "Tokyo Tower",
    lat: 35.6586,
    lng: 139.7454,
    alt: 333.0,
    heading: 220.0,
    tilt: 65.0,
    range: 600.0,
  ),
  PlaceLocation(
    name: "Taj Mahal",
    lat: 27.1751,
    lng: 78.0421,
    alt: 170.0,
    heading: 0.0,
    tilt: 60.0,
    range: 500.0,
  ),
  PlaceLocation(
    name: "Burj Khalifa",
    lat: 25.1972,
    lng: 55.2744,
    alt: 828.0,
    heading: 90.0,
    tilt: 70.0,
    range: 1200.0,
  ),
  PlaceLocation(
    name: "Colosseum",
    lat: 41.8902,
    lng: 12.4922,
    alt: 50.0,
    heading: 135.0,
    tilt: 60.0,
    range: 400.0,
  ),
];
