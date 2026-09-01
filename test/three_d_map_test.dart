import 'package:flutter_test/flutter_test.dart';
import 'package:three_d_map/three_d_map.dart';
import 'package:three_d_map/three_d_map_platform_interface.dart';
import 'package:three_d_map/three_d_map_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockThreeDMapPlatform
    with MockPlatformInterfaceMixin
    implements ThreeDMapPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ThreeDMapPlatform initialPlatform = ThreeDMapPlatform.instance;

  test('$MethodChannelThreeDMap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelThreeDMap>());
  });

  test('getPlatformVersion', () async {
    ThreeDMap threeDMapPlugin = ThreeDMap();
    MockThreeDMapPlatform fakePlatform = MockThreeDMapPlatform();
    ThreeDMapPlatform.instance = fakePlatform;

    expect(await threeDMapPlugin.getPlatformVersion(), '42');
  });
}
