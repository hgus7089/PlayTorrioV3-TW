import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/anime/anime_media.dart';
import 'package:playtorrio/services/anime/anime_scraper_service.dart';
import 'package:playtorrio/services/stream/stream_service.dart';

void main() {
  test('動漫ScraperService generates complete episodes list for releasing anime', () {
    const onePiece = AnimeMedia(
      id: 21,
      titleEnglish: 'ONE PIECE',
      titleRomaji: 'ONE PIECE',
      totalEpisodes: 0, // releasing
      status: 'RELEASING',
      nextAiring: AnimeNextAiring(
        episode: 1123,
        airingAtTimestamp: 1720000000,
        timeUntilAiringSeconds: 3600,
      ),
    );

    final detail = AnimeScraperService.toMovieDetail(onePiece);
    expect(detail.videos.length, 1122);
    expect(detail.videos.first.episode, 1);
    expect(detail.videos.last.episode, 1122);
    print('Successfully generated ${detail.videos.length} episodes for 開啟e Piece!');
  });

  test('StreamService and 動漫ScraperService scrape anime sources by details in player', () async {
    final stream = StreamService.fetchStreamsForTargetAddon(
      targetAddonName: 'Mega播放',
      type: 'anime',
      id: 'anilist:21:1',
      title: 'ONE PIECE - 集 1',
      episode: 1,
    );

    final sources = await stream.take(2).toList();
    expect(sources.isNotEmpty, isTrue);
    for (final s in sources) {
      print('Found in-player source: ${s.name} (${s.url})');
      expect(s.addonName, anyOf('Mega播放', 'AniDB'));
    }
  });
}
