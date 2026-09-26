import 'dart:convert';

import 'package:chuck_interceptor/src/ui/widget/chuck_json_viewer.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('SliverJsonViewer Tests', () {
    Widget wrap(Object? json) => MaterialApp(
      home: Scaffold(body: CustomScrollView(slivers: [SliverJsonViewer(json)])),
    );

    testWidgets('builds only the rows on screen for large arrays', (tester) async {
      final json = jsonDecode(jsonEncode(List.generate(10000, (i) => i)));
      await tester.pumpWidget(wrap(json));

      expect(find.text('[0]'), findsOneWidget);
      expect(find.text('[9999]'), findsNothing);
      expect(tester.widgetList(find.byType(SelectableText)).length, lessThan(100));
    });

    testWidgets('expands and collapses nested objects', (tester) async {
      final json = jsonDecode('{"ok": true, "result": {"id": 89, "tags": ["a", "b"]}}');
      await tester.pumpWidget(wrap(json));

      expect(find.text('ok'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);
      expect(find.text('id'), findsNothing);

      await tester.tap(find.text('Object'));
      // Value labels also handle double tap (copy), so the tap fires after the double tap timeout.
      await tester.pump(kDoubleTapTimeout);
      expect(find.text('id'), findsOneWidget);
      expect(find.text('Array<String>[2]'), findsOneWidget);

      await tester.tap(find.text('Array<String>[2]'));
      await tester.pump(kDoubleTapTimeout);
      expect(find.text('"b"'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
      await tester.pump();
      expect(find.text('id'), findsNothing);
      expect(find.text('"b"'), findsNothing);
    });

    testWidgets('renders placeholder for null root', (tester) async {
      await tester.pumpWidget(wrap(null));

      expect(find.text('{}'), findsOneWidget);
    });
  });
}
