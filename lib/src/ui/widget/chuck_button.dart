import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:material_ui/material_ui.dart';

/// Floating, draggable button which opens the Chuck inspector.
///
/// It replaces the local notification which older Chuck versions used to show.
/// Wrap your application with it (usually through `MaterialApp.builder`) and a
/// small bubble with the number of intercepted calls will float above your UI:
///
/// ```dart
/// MaterialApp(
///   navigatorKey: chuck.navigatorKey,
///   builder: chuck.builder,
///   home: const HomeScreen(),
/// );
/// ```
///
/// The bubble is hidden automatically when Chuck is disabled
/// (`Chuck(enabled: false)`) or while the inspector itself is open.
class ChuckButton extends StatefulWidget {
  /// Creates floating Chuck inspector button.
  const new({
    required this.chuckCore,
    this.child,
    this.visible = true,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
    this.draggable = true,
    this.hideWhenEmpty = false,
    super.key,
  });

  /// Chuck core instance which holds intercepted calls.
  final ChuckCore chuckCore;

  /// Application widget rendered below the button.
  final Widget? child;

  /// Whether the button should be rendered at all.
  final bool visible;

  /// Where the button is placed before it gets dragged.
  final Alignment alignment;

  /// Distance kept between the button and the screen edges.
  final EdgeInsets padding;

  /// Whether user can drag the button around the screen.
  final bool draggable;

  /// Whether the button is hidden until the first HTTP call is intercepted.
  final bool hideWhenEmpty;

  @override
  State<ChuckButton> createState() => _ChuckButtonState();
}

class _ChuckButtonState extends State<ChuckButton> {
  static const double _buttonSize = 56;

  Offset? _position;
  EdgeInsets _safeArea = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child ?? const SizedBox.shrink();
    if (!widget.visible || !widget.chuckCore.enabled) {
      return child;
    }

    _safeArea = MediaQuery.maybeViewPaddingOf(context) ?? EdgeInsets.zero;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: child),
            ValueListenableBuilder<bool>(
              valueListenable: widget.chuckCore.inspectorOpened,
              builder: (context, inspectorOpened, _) =>
                  inspectorOpened ? const SizedBox.shrink() : _buildStream(context, constraints),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStream(BuildContext context, BoxConstraints constraints) => StreamBuilder<List<ChuckHttpCall>>(
    stream: widget.chuckCore.callsStream,
    initialData: widget.chuckCore.callsSubject.valueOrNull ?? const [],
    builder: (context, snapshot) {
      final List<ChuckHttpCall> calls = snapshot.data ?? const [];
      if (widget.hideWhenEmpty && calls.isEmpty) {
        return const SizedBox.shrink();
      }
      final Offset offset = _resolvePosition(constraints);
      return Transform.translate(
        offset: offset,
        child: Align(alignment: Alignment.topLeft, child: _buildBubble(context, calls, constraints)),
      );
    },
  );

  Offset _resolvePosition(BoxConstraints constraints) {
    final Offset? position = _position;
    if (position != null) {
      return _clamp(position, constraints);
    }
    final EdgeInsets inset = _insets;
    final double maxX = constraints.maxWidth - _buttonSize - inset.right;
    final double maxY = constraints.maxHeight - _buttonSize - inset.bottom;
    final double x = inset.left + ((widget.alignment.x + 1) / 2) * (maxX - inset.left);
    final double y = inset.top + ((widget.alignment.y + 1) / 2) * (maxY - inset.top);
    return _clamp(Offset(x, y), constraints);
  }

  /// Configured padding, grown by the device safe area so the button never
  /// lands under a notch, a status bar or the home indicator.
  EdgeInsets get _insets => EdgeInsets.fromLTRB(
    widget.padding.left + _safeArea.left,
    widget.padding.top + _safeArea.top,
    widget.padding.right + _safeArea.right,
    widget.padding.bottom + _safeArea.bottom,
  );

  Offset _clamp(Offset offset, BoxConstraints constraints) {
    final EdgeInsets inset = _insets;
    final double maxX = (constraints.maxWidth - _buttonSize - inset.right).clamp(0.0, double.infinity);
    final double maxY = (constraints.maxHeight - _buttonSize - inset.bottom).clamp(0.0, double.infinity);
    return Offset(
      offset.dx.clamp(inset.left, maxX < inset.left ? inset.left : maxX),
      offset.dy.clamp(inset.top, maxY < inset.top ? inset.top : maxY),
    );
  }

  Widget _buildBubble(BuildContext context, List<ChuckHttpCall> calls, BoxConstraints constraints) {
    final _ChuckCallsSummary summary = _ChuckCallsSummary.of(calls);
    final ThemeData theme = Theme.of(context);
    final Color background = summary.errorCalls > 0
        ? const Color(0xffd32f2f)
        : summary.loadingCalls > 0
        ? const Color(0xfff57c00)
        : theme.colorScheme.primary;

    return GestureDetector(
      onTap: widget.chuckCore.navigateToCallListScreen,
      onPanUpdate: widget.draggable
          ? (details) => setState(() {
              _position = _clamp(_resolvePosition(constraints) + details.delta, constraints);
            })
          : null,
      child: Material(
        color: background,
        elevation: 6,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: summary.tooltip(calls.length),
          child: SizedBox.square(
            dimension: _buttonSize,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.http, color: Colors.white, size: 20),
                Text(
                  calls.length > 999 ? '999+' : '${calls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aggregated counters of intercepted calls, used for the button badge.
class _ChuckCallsSummary {
  const new({
    required this.loadingCalls,
    required this.successCalls,
    required this.redirectCalls,
    required this.errorCalls,
  });

  factory of(List<ChuckHttpCall> calls) {
    int loading = 0;
    int success = 0;
    int redirect = 0;
    int error = 0;
    for (final ChuckHttpCall call in calls) {
      if (call.loading) {
        loading++;
        continue;
      }
      final int? status = call.response?.status;
      if (call.error != null || status == null || status >= 400) {
        error++;
      } else if (status >= 300) {
        redirect++;
      } else if (status >= 200) {
        success++;
      }
    }
    return _ChuckCallsSummary(loadingCalls: loading, successCalls: success, redirectCalls: redirect, errorCalls: error);
  }

  final int loadingCalls;
  final int successCalls;
  final int redirectCalls;
  final int errorCalls;

  String tooltip(int total) {
    final List<String> parts = [
      if (loadingCalls > 0) 'Loading: $loadingCalls',
      if (successCalls > 0) 'Success: $successCalls',
      if (redirectCalls > 0) 'Redirect: $redirectCalls',
      if (errorCalls > 0) 'Error: $errorCalls',
    ];
    if (parts.isEmpty) {
      return 'Chuck HTTP Inspector';
    }
    return 'Chuck (total: $total) — ${parts.join(' | ')}';
  }
}
