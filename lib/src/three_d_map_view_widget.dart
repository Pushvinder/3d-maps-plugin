import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'map_3d_mode.dart';
import 'map_marker.dart';
import 'three_d_map_controller.dart';

typedef MapCreatedCallback = void Function(ThreeDMapController controller);
typedef MapClickCallback = void Function(
    double lat, double lng, double alt, String? placeId);
typedef MarkerTapCallback = void Function(MapMarker marker);
typedef MapErrorCallback = void Function(String error);

/// Flutter widget displaying a 3D Google Map view on Android with native markers.
class ThreeDMapViewWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialAlt;
  final double heading;
  final double tilt;
  final double range;
  final Map3DMode mapMode;
  final bool showSearchBar;
  final List<MapMarker> markers;
  final double? imageSize;
  final double? imageRadius;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onMapReady;
  final MapClickCallback? onMapClick;
  final MarkerTapCallback? onMarkerTap;
  final MapErrorCallback? onError;

  const ThreeDMapViewWidget({
    super.key,
    this.initialLat = 38.544012,
    this.initialLng = -107.670428,
    this.initialAlt = 2427.6,
    this.heading = 310.0,
    this.tilt = 63.0,
    this.range = 8266.0,
    this.mapMode = Map3DMode.hybrid,
    this.showSearchBar = false,
    this.markers = const [],
    this.imageSize,
    this.imageRadius,
    this.onMapCreated,
    this.onMapReady,
    this.onMapClick,
    this.onMarkerTap,
    this.onError,
  });

  @override
  State<ThreeDMapViewWidget> createState() => _ThreeDMapViewWidgetState();
}

class _ThreeDMapViewWidgetState extends State<ThreeDMapViewWidget> {
  ThreeDMapController? _controller;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Center(
        child: Text(
          '$defaultTargetPlatform is not supported by three_d_map.',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final creationParams = <String, dynamic>{
      'initialLat': widget.initialLat,
      'initialLng': widget.initialLng,
      'initialAlt': widget.initialAlt,
      'heading': widget.heading,
      'tilt': widget.tilt,
      'range': widget.range,
      'mapMode': widget.mapMode.value,
      'showSearchBar': widget.showSearchBar,
      if (widget.imageSize != null) 'imageSize': widget.imageSize,
      if (widget.imageRadius != null) 'imageRadius': widget.imageRadius,
    };

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.app.three_d_map/view',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return PlatformViewLink(
      viewType: 'com.app.three_d_map/view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'com.app.three_d_map/view',
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            _onPlatformViewCreated(id);
          })
          ..create();
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('com.app.three_d_map/view_$id');
    final controller = ThreeDMapController(channel);
    _controller = controller;

    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMapReady':
          _syncMarkers();
          if (widget.onMapReady != null) {
            widget.onMapReady!();
          }
          break;
        case 'onMapClick':
          final args = call.arguments as Map?;
          if (args != null && widget.onMapClick != null) {
            final lat = (args['lat'] as num).toDouble();
            final lng = (args['lng'] as num).toDouble();
            final alt = (args['alt'] as num).toDouble();
            final placeId = args['placeId'] as String?;
            widget.onMapClick!(lat, lng, alt, placeId);
          }
          break;
        case 'onMarkerClick':
          final args = call.arguments as Map?;
          if (args != null) {
            final markerId = args['markerId'] as String?;
            if (markerId != null) {
              final marker = widget.markers.firstWhere(
                (m) => m.id == markerId,
                orElse: () => MapMarker(
                  id: markerId,
                  latitude: (args['lat'] as num?)?.toDouble() ?? 0.0,
                  longitude: (args['lng'] as num?)?.toDouble() ?? 0.0,
                  altitude: (args['alt'] as num?)?.toDouble() ?? 0.0,
                  title: args['title'] as String?,
                  snippet: args['snippet'] as String?,
                ),
              );
              if (marker.onTap != null) {
                marker.onTap!();
              }
              if (widget.onMarkerTap != null) {
                widget.onMarkerTap!(marker);
              }
            }
          }
          break;
        case 'onError':
          final args = call.arguments as Map?;
          if (args != null && widget.onError != null) {
            widget.onError!(args['error'] as String? ?? 'Unknown error');
          }
          break;
      }
    });

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  void _syncMarkers() {
    if (_controller == null || widget.markers.isEmpty) return;
    for (final marker in widget.markers) {
      _controller!.addMarker(marker.toMap());
    }
  }
}
