import '../../models/anime/anime_media.dart';
import '../../models/stream/stream_model.dart';
import 'anime_scraper_service.dart';

class AnimeStreamService {
  static final AnimeStreamService instance = AnimeStreamService._internal();
  AnimeStreamService._internal();

  final AnimeScraperService _scraper = AnimeScraperService.instance;

  List<AnimeEpisode> getEpisodes(AnimeMedia anime) {
    final count = anime.totalEpisodes > 0 ? anime.totalEpisodes : 24;
    return List.generate(
      count,
      (i) => AnimeEpisode(
        number: i + 1,
        title: 'Episode ${i + 1}',
        thumbnail: anime.backdropUrl,
        description: 'Episode ${i + 1} of ${anime.displayTitle}',
      ),
    );
  }

  Stream<StreamSource> getEpisodeStreams({
    required AnimeMedia anime,
    required int episodeNumber,
    String? categoryFilter,
  }) {
    return _scraper.scrapeStreamsStream(
      anime: anime,
      episodeNumber: episodeNumber,
      categoryFilter: categoryFilter,
    );
  }
}
