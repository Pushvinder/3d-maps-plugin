import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_3d_map/flutter_3d_map.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final Flutter3DMap plugin = Flutter3DMap();
    final String? version = await plugin.getPlatformVersion();
    expect(version?.isNotEmpty, true);
  });
}
