import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ChuckButton Tests', () {
    late ChuckCore chuckCore;

    setUp(() {
      chuckCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        showInspectorOnShake: false,
        maxCallsCount: 10,
      );
    });

    tearDown(() {
      chuckCore.dispose();
    });

    Widget wrap({bool hideWhenEmpty = false, bool visible = true}) =>
        MaterialApp(
          builder: (context, child) => ChuckButton(
            chuckCore: chuckCore,
            visible: visible,
            hideWhenEmpty: hideWhenEmpty,
            child: child,
          ),
          home: const Scaffold(body: Text('app')),
        );

    testWidgets('renders call counter above the app', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('app'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      chuckCore.addCall(ChuckHttpCall(1)..endpoint = '/first');
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets(
      'hides itself when hideWhenEmpty is set and there are no calls',
      (tester) async {
        await tester.pumpWidget(wrap(hideWhenEmpty: true));

        expect(find.byIcon(Icons.http), findsNothing);

        chuckCore.addCall(ChuckHttpCall(1)..endpoint = '/first');
        await tester.pump();

        expect(find.byIcon(Icons.http), findsOneWidget);
      },
    );

    testWidgets('is not rendered when visible is false', (tester) async {
      await tester.pumpWidget(wrap(visible: false));

      expect(find.text('app'), findsOneWidget);
      expect(find.byIcon(Icons.http), findsNothing);
    });

    testWidgets('is not rendered when Chuck is disabled', (tester) async {
      final disabledCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        enabled: false,
        showInspectorOnShake: false,
        maxCallsCount: 10,
      );
      addTearDown(disabledCore.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              ChuckButton(chuckCore: disabledCore, child: child),
          home: const Scaffold(body: Text('app')),
        ),
      );

      expect(find.byIcon(Icons.http), findsNothing);
    });

    testWidgets('opens the inspector on tap', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final core = ChuckCore(
        navigatorKey,
        showInspectorOnShake: false,
        maxCallsCount: 10,
      );
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              ChuckButton(chuckCore: core, child: child),
          home: const Scaffold(body: Text('app')),
        ),
      );

      await tester.tap(find.byIcon(Icons.http));
      await tester.pumpAndSettle();

      expect(core.inspectorOpened.value, isTrue);
      // Button hides itself while the inspector is on screen.
      expect(find.byIcon(Icons.http), findsNothing);
    });
  });
}
