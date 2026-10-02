import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChuckCore createCore({String? appName, String? appVersion, Future<void> Function(String)? onShare}) => ChuckCore(
    GlobalKey<NavigatorState>(),
    showInspectorOnShake: false,
    darkTheme: false,
    maxCallsCount: 10,
    appName: appName,
    appVersion: appVersion,
    onShare: onShare,
  );

  ChuckHttpCall createCall() => ChuckHttpCall(1, DateTime.now())
    ..request = ChuckHttpRequest(time: DateTime.now())
    ..response = ChuckHttpResponse(status: 200, body: 'ok');

  /// Records every `Clipboard.setData` text sent to the platform.
  List<String> mockClipboard() {
    final List<String> copied = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return copied;
  }

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  group('ChuckSaveHelper.share', () {
    testWidgets('copies to clipboard and shows a snack bar without onShare', (tester) async {
      final copied = mockClipboard();
      final core = createCore();
      addTearDown(core.dispose);
      final context = await pumpContext(tester);

      await ChuckSaveHelper.share(context, core, 'log');
      await tester.pump();

      expect(copied, ['log']);
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('calls onShare and skips the clipboard', (tester) async {
      final copied = mockClipboard();
      final List<String> shared = [];
      final core = createCore(onShare: (text) async => shared.add(text));
      addTearDown(core.dispose);
      final context = await pumpContext(tester);

      await ChuckSaveHelper.share(context, core, 'log');
      await tester.pump();

      expect(shared, ['log']);
      expect(copied, isEmpty);
      expect(find.text('Copied to clipboard'), findsNothing);
    });
  });

  group('ChuckSaveHelper.buildCallLog', () {
    test('omits app info rows when not given', () {
      final core = createCore();
      addTearDown(core.dispose);

      final log = ChuckSaveHelper.buildCallLog(core, createCall());

      // Header goes straight to the timestamp: no empty or "null" app rows.
      expect(log, startsWith('Chuck - HTTP Inspector\nGenerated:'));
      expect(log, isNot(contains('App name')));
    });

    test('writes app info rows when given', () {
      final core = createCore(appName: 'MyApp', appVersion: '1.2.3+4');
      addTearDown(core.dispose);

      final log = ChuckSaveHelper.buildCallLog(core, createCall());

      expect(log, contains('App name: MyApp\n'));
      expect(log, contains('Version: 1.2.3+4\n'));
    });
  });
}
