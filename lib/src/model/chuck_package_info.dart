/// Basic information about the host application, written into the header of exported logs.
///
/// Chuck does not depend on `package_info_plus`; supply it through `Chuck.packageInfoProvider`:
///
/// ```dart
/// Chuck(
///   packageInfoProvider: () async {
///     final info = await PackageInfo.fromPlatform();
///     return ChuckPackageInfo(
///       appName: info.appName,
///       packageName: info.packageName,
///       version: info.version,
///       buildNumber: info.buildNumber,
///     );
///   },
/// );
/// ```
final class ChuckPackageInfo {
  const new({required this.appName, required this.packageName, required this.version, required this.buildNumber});

  /// Application name.
  final String appName;

  /// Package name / bundle identifier.
  final String packageName;

  /// Application version.
  final String version;

  /// Application build number.
  final String buildNumber;
}
