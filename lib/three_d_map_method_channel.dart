import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'three_d_map_platform_interface.dart';

/// An implementation of [ThreeDMapPlatform] that uses method channels.
class MethodChannelThreeDMap extends ThreeDMapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('three_d_map');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
