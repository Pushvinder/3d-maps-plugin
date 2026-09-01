import 'package:flutter/material.dart';

/// Represents a 3D marker on the map.
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final double altitude;
  final String? title;
  final String? snippet;
  final String? iconAsset;
  final String? imageUrl;
  final IconData? iconData;
  final Color color;
  final VoidCallback? onTap;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.title,
    this.snippet,
    this.iconAsset,
    this.imageUrl,
    this.iconData = Icons.location_on,
    this.color = Colors.red,
    this.onTap,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': latitude,
      'lng': longitude,
      'alt': altitude,
      'title': title,
      'snippet': snippet,
      'iconAsset': iconAsset,
      'imageUrl': imageUrl,
    };
  }

  MapMarker copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? altitude,
    String? title,
    String? snippet,
    String? iconAsset,
    String? imageUrl,
    IconData? iconData,
    Color? color,
    VoidCallback? onTap,
  }) {
    return MapMarker(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      iconAsset: iconAsset ?? this.iconAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
      onTap: onTap ?? this.onTap,
    );
  }
}
