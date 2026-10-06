import 'three_d_map_platform_interface.dart';

export 'src/map_3d_mode.dart';
export 'src/map_marker.dart';
export 'src/place_location.dart';
export 'src/three_d_map_controller.dart';
export 'src/three_d_map_view_widget.dart';

class Flutter3DMap {
  Future<String?> getPlatformVersion() {
    return ThreeDMapPlatform.instance.getPlatformVersion();
  }
}
