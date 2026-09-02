import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/scraper/sites/vadapav.dart';
import 'package:playtorrio/services/addon/addon_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowAllHttpOverrides();

  group('VadapavScraper Tests', () {
    test('Fetches streams for movie and TV series', () async {
      final scraper = VadapavScraper();

      print('Testing Vadapav for movie: Fight Club (tt0137523)...');
      final movieStream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        imdbId: 'tt0137523',
        year: 1999,
      );

      final movieSources = await movieStream.toList();
      print('Received ${movie來源.length} movie streams from vadapav:');
      for (final s in movieSources) {
        print('  - ${s.title} (畫質: ${s.quality}, 編碼: ${s.codec})');
        print('    URL: ${s.url}');
      }

      expect(movieSources, isNotEmpty);
      expect(movieSources.first.url, startsWith('http'));
      expect(movieSources.first.addonName, '播放TorrioHTTP');

      print('\nTesting Vadapav for series: Breaking Bad S01E01 (tt0903747)...');
      final tvStream = scraper.scrapeStream(
        type: 'series',
        title: 'Breaking Bad',
        imdbId: 'tt0903747',
        season: 1,
        episode: 1,
        year: 2008,
      );

      final tvSources = await tvStream.toList();
      print('Received ${tv來源.length} series streams from vadapav:');
      for (final s in tvSources) {
        print('  - ${s.title} (畫質: ${s.quality}, 編碼: ${s.codec})');
        print('    URL: ${s.url}');
      }

      expect(tvSources, isNotEmpty);
      expect(tvSources.first.url, startsWith('http'));
      expect(tvSources.first.addonName, '播放TorrioHTTP');
    });
  });

  group('Stremio Scheme Normalization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('新增on管理r accepts stremio:// URLs correctly', () async {
      final manager = AddonManager.instance;
      await manager.initialize();

      // Test adding with stremio:// protocol
      const url = 'stremio://stremio.vadapav.mov/manifest.json';
      print('Testing adding addon with stremio:// protocol: $url');
      final addon = await manager.addAddon(url);

      print('Successfully installed: ${addon.manifest.name} (id: ${addon.manifest.id})');
      expect(addon.baseUrl, 'https://stremio.vadapav.mov');
      expect(addon.manifest.id, 'org.stremio.vadapav');
    });
  });
}
