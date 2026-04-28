import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/core/services/app_update_service.dart';

void main() {
  group('compareSemanticVersions', () {
    test('handles tag prefixes and build metadata', () {
      expect(compareSemanticVersions('v1.2.0+7', '1.1.9'), greaterThan(0));
      expect(compareSemanticVersions('1.0.0+7', 'v1.0.0+99'), lessThan(0));
    });

    test('compares each semantic part numerically', () {
      expect(compareSemanticVersions('1.10.0', '1.2.0'), greaterThan(0));
      expect(compareSemanticVersions('2.0.0', '2.0.1'), lessThan(0));
    });
  });

  group('parseGithubRelease', () {
    test('prefers dmg assets when present', () {
      final release = parseGithubRelease({
        'tag_name': 'v1.3.0',
        'html_url': 'https://github.com/ITfisher/lumi/releases/tag/v1.3.0',
        'published_at': '2026-04-28T08:00:00Z',
        'assets': [
          {
            'name': 'lumi-1.3.0-macos-arm64.dmg',
            'browser_download_url': 'https://example.com/lumi.dmg',
          },
        ],
      }, 'https://github.com/ITfisher/lumi/releases');

      expect(release, isNotNull);
      expect(release!.version, '1.3.0');
      expect(release.hasDmgAsset, isTrue);
      expect(release.downloadUrl, 'https://example.com/lumi.dmg');
    });

    test('falls back to release page when no dmg is attached', () {
      final release = parseGithubRelease({
        'tag_name': 'v1.3.0',
        'html_url': 'https://github.com/ITfisher/lumi/releases/tag/v1.3.0',
        'assets': const [],
      }, 'https://github.com/ITfisher/lumi/releases');

      expect(release, isNotNull);
      expect(release!.hasDmgAsset, isFalse);
      expect(
        release.downloadUrl,
        'https://github.com/ITfisher/lumi/releases/tag/v1.3.0',
      );
    });
  });

  group('selectGithubRelease', () {
    test('skips prerelease builds when disabled', () {
      final release = selectGithubRelease([
        {
          'tag_name': 'v1.0.0+7',
          'prerelease': true,
          'draft': false,
          'html_url': 'https://github.com/ITfisher/lumi/releases/tag/v1.0.0+7',
          'assets': const [],
        },
        {
          'tag_name': 'v1.0.0',
          'prerelease': false,
          'draft': false,
          'html_url': 'https://github.com/ITfisher/lumi/releases/tag/v1.0.0',
          'assets': const [],
        },
      ], 'https://github.com/ITfisher/lumi/releases', includePrerelease: false);

      expect(release, isNotNull);
      expect(release!.version, '1.0.0');
      expect(release.isPrerelease, isFalse);
    });

    test('returns prerelease builds when enabled', () {
      final release = selectGithubRelease([
        {
          'tag_name': 'v1.0.0+7',
          'prerelease': true,
          'draft': false,
          'html_url': 'https://github.com/ITfisher/lumi/releases/tag/v1.0.0+7',
          'assets': const [],
        },
      ], 'https://github.com/ITfisher/lumi/releases', includePrerelease: true);

      expect(release, isNotNull);
      expect(release!.version, '1.0.0+7');
      expect(release.isPrerelease, isTrue);
    });
  });
}
