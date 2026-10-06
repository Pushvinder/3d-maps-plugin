import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_3d_map_example/main.dart';

void main() {
  testWidgets('Verify widget pumps', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ThreeDMapExampleScreen(),
    ));
  });
}
