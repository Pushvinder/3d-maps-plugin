import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'three_d_map_method_channel.dart';

abstract class ThreeDMapPlatform extends PlatformInterface {
  /// Constructs a ThreeDMapPlatform.
  ThreeDMapPlatform() : super(token: _token);

  static final Object _token = Object();

  static ThreeDMapPlatform _instance = MethodChannelThreeDMap();

  /// The default instance of [ThreeDMapPlatform] to use.
  ///
  /// Defaults to [MethodChannelThreeDMap].
  static ThreeDMapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ThreeDMapPlatform] when
  /// they register themselves.
  static set instance(ThreeDMapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
