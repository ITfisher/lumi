import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.version,
    required this.releaseUrl,
    required this.downloadUrl,
    required this.assetName,
    required this.publishedAt,
    required this.isPrerelease,
  });

  final String version;
  final String releaseUrl;
  final String downloadUrl;
  final String? assetName;
  final DateTime? publishedAt;
  final bool isPrerelease;

  bool get hasDmgAsset => assetName != null;
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.currentVersion,
    required this.latestRelease,
    required this.hasUpdate,
  });

  final String currentVersion;
  final AppReleaseInfo latestRelease;
  final bool hasUpdate;
}

class AppUpdateService {
  AppUpdateService({
    this.owner = 'ITfisher',
    this.repository = 'lumi',
    Future<List<Map<String, dynamic>>> Function()? releasesLoader,
  }) : _releasesLoader = releasesLoader;

  final String owner;
  final String repository;
  final Future<List<Map<String, dynamic>>> Function()? _releasesLoader;

  String get releasesPageUrl =>
      'https://github.com/$owner/$repository/releases';

  Future<String> getCurrentVersion() async {
    final bundleVersion = await _readMacOsBundleVersion();
    if (bundleVersion != null && bundleVersion.isNotEmpty) {
      return bundleVersion;
    }

    final pubspecVersion = await _readLocalPubspecVersion();
    if (pubspecVersion != null && pubspecVersion.isNotEmpty) {
      return normalizeReleaseVersion(pubspecVersion);
    }

    return '0.0.0';
  }

  Future<AppUpdateCheckResult> checkForUpdates({
    bool includePrerelease = false,
  }) async {
    final currentVersion = await getCurrentVersion();
    final releasesJson = await _loadReleasesJson();
    final latestRelease = selectGithubRelease(
      releasesJson,
      releasesPageUrl,
      includePrerelease: includePrerelease,
    );
    if (latestRelease == null) {
      throw StateError(
        includePrerelease
            ? 'No GitHub releases are available yet.'
            : 'No stable GitHub release is available yet.',
      );
    }

    return AppUpdateCheckResult(
      currentVersion: currentVersion,
      latestRelease: latestRelease,
      hasUpdate:
          compareSemanticVersions(latestRelease.version, currentVersion) > 0,
    );
  }

  Future<bool> openUrl(String url) async {
    if (kIsWeb) return false;

    try {
      late final ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        result = await Process.run(
          'rundll32',
          ['url.dll,FileProtocolHandler', url],
        );
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [url]);
      } else {
        return false;
      }
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadReleasesJson() async {
    if (_releasesLoader != null) {
      return _releasesLoader();
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          'https://api.github.com/repos/$owner/$repository/releases',
        ),
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'lumi-update-check');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'GitHub API responded with ${response.statusCode}: $body',
          uri: request.uri,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const FormatException('Unexpected GitHub releases payload.');
      }

      return decoded.whereType<Map<String, dynamic>>().toList();
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _readMacOsBundleVersion() async {
    if (kIsWeb || !Platform.isMacOS) return null;

    try {
      final infoPlist = File(
        p.join(
          File(Platform.resolvedExecutable).parent.parent.path,
          'Info.plist',
        ),
      );
      if (!await infoPlist.exists()) return null;

      final content = await infoPlist.readAsString();
      final shortVersion =
          _readPlistValue(content, 'CFBundleShortVersionString');
      final buildNumber = _readPlistValue(content, 'CFBundleVersion');
      if (shortVersion == null || shortVersion.isEmpty) {
        return buildNumber == null
            ? null
            : normalizeReleaseVersion(buildNumber);
      }
      if (buildNumber == null || buildNumber.isEmpty) {
        return normalizeReleaseVersion(shortVersion);
      }
      return '${normalizeReleaseVersion(shortVersion)}+$buildNumber';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readLocalPubspecVersion() async {
    try {
      final pubspec = File(p.join(Directory.current.path, 'pubspec.yaml'));
      if (!await pubspec.exists()) return null;

      final content = await pubspec.readAsString();
      final match = RegExp(r'^version:\s*([^\s]+)\s*$', multiLine: true)
          .firstMatch(content);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }
}

AppReleaseInfo? parseGithubRelease(
  Map<String, dynamic> json,
  String fallbackReleaseUrl,
) {
  final tagName = (json['tag_name'] as String?)?.trim();
  final releaseName = (json['name'] as String?)?.trim();
  final releaseUrl = (json['html_url'] as String?)?.trim().isNotEmpty == true
      ? (json['html_url'] as String).trim()
      : fallbackReleaseUrl;
  final version = normalizeReleaseVersion(tagName ?? releaseName ?? '');
  if (version.isEmpty) return null;

  final assets = (json['assets'] as List<dynamic>? ?? const []);
  String? assetName;
  var downloadUrl = releaseUrl;

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) continue;
    final name = (asset['name'] as String?)?.trim() ?? '';
    final url = (asset['browser_download_url'] as String?)?.trim() ?? '';
    if (!name.toLowerCase().endsWith('.dmg') || url.isEmpty) continue;

    assetName = name;
    downloadUrl = url;
    break;
  }

  final publishedAtRaw = (json['published_at'] as String?)?.trim();

  return AppReleaseInfo(
    version: version,
    releaseUrl: releaseUrl,
    downloadUrl: downloadUrl,
    assetName: assetName,
    publishedAt: publishedAtRaw == null || publishedAtRaw.isEmpty
        ? null
        : DateTime.tryParse(publishedAtRaw),
    isPrerelease: json['prerelease'] == true,
  );
}

AppReleaseInfo? selectGithubRelease(
  List<Map<String, dynamic>> releases,
  String fallbackReleaseUrl, {
  required bool includePrerelease,
}) {
  for (final releaseJson in releases) {
    if (releaseJson['draft'] == true) continue;
    if (!includePrerelease && releaseJson['prerelease'] == true) continue;

    final release = parseGithubRelease(releaseJson, fallbackReleaseUrl);
    if (release != null) return release;
  }

  return null;
}

int compareSemanticVersions(String a, String b) {
  final left = _versionParts(a);
  final right = _versionParts(b);
  final maxLength = left.length > right.length ? left.length : right.length;

  for (var index = 0; index < maxLength; index++) {
    final leftPart = index < left.length ? left[index] : 0;
    final rightPart = index < right.length ? right[index] : 0;
    if (leftPart != rightPart) {
      return leftPart.compareTo(rightPart);
    }
  }

  return 0;
}

String normalizeReleaseVersion(String raw) {
  var value = raw.trim();
  if (value.startsWith('v') || value.startsWith('V')) {
    value = value.substring(1);
  }
  final spaceIndex = value.indexOf(' ');
  if (spaceIndex >= 0) {
    value = value.substring(0, spaceIndex);
  }
  final dashIndex = value.indexOf('-');
  if (dashIndex >= 0) {
    value = value.substring(0, dashIndex);
  }
  return value.trim();
}

List<int> _versionParts(String version) {
  final normalized = normalizeReleaseVersion(version);
  if (normalized.isEmpty) return const [0];

  final versionAndBuild = normalized.split('+');
  final semanticParts = versionAndBuild.first.split('.').map((segment) {
    final digits = RegExp(r'\d+').stringMatch(segment);
    return int.tryParse(digits ?? '0') ?? 0;
  }).toList();
  final buildPart = versionAndBuild.length > 1
      ? int.tryParse(RegExp(r'\d+').stringMatch(versionAndBuild[1]) ?? '0') ?? 0
      : 0;

  return [...semanticParts, buildPart];
}

String? _readPlistValue(String content, String key) {
  final pattern = RegExp(
    '<key>$key</key>\\s*<string>([^<]+)</string>',
    multiLine: true,
  );
  return pattern.firstMatch(content)?.group(1)?.trim();
}
