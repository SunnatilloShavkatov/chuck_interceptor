/// What Chuck asks the host app to share. Exactly one of [text] or [filePath] is set.
///
/// Chuck does not depend on a share plugin; pass `Chuck.onShare` and forward this to the one you use:
///
/// ```dart
/// Chuck(
///   onShare: (content) async {
///     await SharePlus.instance.share(
///       ShareParams(
///         subject: content.subject,
///         text: content.text,
///         files: content.filePath == null ? null : [XFile(content.filePath!)],
///       ),
///     );
///   },
/// );
/// ```
final class ChuckShareContent {
  const new({required this.subject, this.text, this.filePath});

  /// Suggested subject / title for the share sheet.
  final String subject;

  /// Plain text to share (a single call's details).
  final String? text;

  /// Path of a saved log file to share (all calls).
  final String? filePath;
}

/// Callback Chuck invokes to share logs. When no callback is provided, Chuck hides every share action.
typedef ChuckShareCallback = Future<void> Function(ChuckShareContent content);
