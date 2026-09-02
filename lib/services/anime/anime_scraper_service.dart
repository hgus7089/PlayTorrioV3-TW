import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/anime/anime_media.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../models/stream/stream_model.dart';
import 'extractors/anidb_extractor.dart';
import 'extractors/megaplay_extractor.dart';
import 'extractors/recloud_extractor.dart';
import 'extractors/tryembed_extractor.dart';
import 'extractors/watchhentai_extractor.dart';
import 'extractors/hentaini_extractor.dart';

class AnimeScraperService {
  static final AnimeScraperService instance = AnimeScraperService._internal();
  AnimeScraperService._internal();

  final MegaPlayExtractor _megaPlay = MegaPlayExtractor.instance;
  final ReCloudExtractor _reCloud = ReCloudExtractor.instance;
  final TryEmbedExtractor _tryEmbed = TryEmbedExtractor.instance;
  final AniDbExtractor _aniDb = AniDbExtractor.instance;
  final WatchHentaiExtractor _watchHentai = WatchHentaiExtractor();
  final HentainiExtractor _hentaini = HentainiExtractor();

  static String cleanAnimeTitle(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'\s*-\s*集\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\s*•\s*Ep\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\s*•\s*集\s*\d+.*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\(TV\)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\[.*?\]'), '');
    return s.trim();
  }

  /// Scrape all stream sources for an Anime and Episode across all native extractors concurrently.
  Stream<StreamSource> scrapeStreamsStream({
    required AnimeMedia anime,
    required int episodeNumber,
    String? categoryFilter, // 'sub', 'dub', or null for both
  }) {
    final controller = StreamController<StreamSource>();
    final seenUrls = <String>{};

    final titleCandidates = [
      anime.titleEnglish,
      anime.titleRomaji,
      anime.titleUserPreferred,
      anime.titleNative,
    ].where((t) => t.trim().isNotEmpty).toList();

    () async {
      final tasks = <Future>[];
      final cats = categoryFilter != null ? [categoryFilter.toLowerCase()] : ['sub', 'dub'];

      // 1. MegaPlay Provider (Sub & Dub)
      for (final cat in cats) {
        tasks.add(
          _megaPlay
              .extract(
            anilistId: anime.id,
            episodeNumber: episodeNumber,
            category: cat,
          )
              .then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              final catUpper = cat.toUpperCase();
              final subCount = res.tracks.where((t) => t.kind != 'thumbnails').length;
              final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

              controller.add(
                StreamSource(
                  name: '⚡ Mega播放 • $catUpper',
                  title:
                      '${anime.displayTitle} • Ep $episodeNumber [Mega播放 • $catUpper]',
                  description:
                      'Mega播放 • Master HLS • $catUpper$subLabel',
                  url: res.url,
                  addonName: 'Mega播放',
                  headers: res.headers,
                  behaviorHints: {
                    'notWebReady': false,
                    if (res.intro != null) 'intro': res.intro,
                    if (res.outro != null) 'outro': res.outro,
                    'proxyHeaders': {
                      'request': res.headers,
                    },
                  },
                ),
              );
            }
          }).catchError((e) {
            if (kDebugMode) debugPrint('[動漫Scraper] Mega播放 ($cat) error: $e');
          }),
        );
      }

      // 2. ReCloud Provider (Sub & Dub)
      for (final cat in cats) {
        tasks.add(
          _reCloud
              .extract(
            anilistId: anime.id,
            episodeNumber: episodeNumber,
            category: cat,
          )
              .then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              final catUpper = cat.toUpperCase();
              final subCount = res.tracks.where((t) => t.kind != 'thumbnails').length;
              final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

              controller.add(
                StreamSource(
                  name: '⚡ ReCloud • $catUpper',
                  title:
                      '${anime.displayTitle} • Ep $episodeNumber [ReCloud • $catUpper]',
                  description:
                      'ReCloud • Master HLS • $catUpper$subLabel',
                  url: res.url,
                  addonName: 'ReCloud',
                  headers: res.headers,
                  behaviorHints: {
                    'notWebReady': true,
                    if (res.intro != null) 'intro': res.intro,
                    if (res.outro != null) 'outro': res.outro,
                    'proxyHeaders': {
                      'request': res.headers,
                    },
                  },
                ),
              );
            }
          }).catchError((e) {
            if (kDebugMode) debugPrint('[動漫Scraper] ReCloud ($cat) error: $e');
          }),
        );
      }

      // 3. TryEmbed Provider (Sub & Dub)
      for (final cat in cats) {
        tasks.add(
          _tryEmbed
              .extractAll(
            anilistId: anime.id,
            episodeNumber: episodeNumber,
            category: cat,
          )
              .then((results) {
            for (final res in results) {
              if (res.url.isNotEmpty &&
                  seenUrls.add(res.url) &&
                  !controller.isClosed) {
                final catUpper = cat.toUpperCase();
                final subCount = res.tracks.length;
                final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

                controller.add(
                  StreamSource(
                    name: '⚡ TryEmbed • ${res.serverName} • $catUpper',
                    title:
                        '${anime.displayTitle} • Ep $episodeNumber [TryEmbed • ${res.serverName} • $catUpper]',
                    description:
                        'TryEmbed (${res.serverName}) • Master HLS • $catUpper$subLabel',
                    url: res.url,
                    addonName: 'TryEmbed',
                    headers: res.headers,
                    behaviorHints: {
                      'notWebReady': false,
                      if (res.intro != null) 'intro': res.intro,
                      if (res.outro != null) 'outro': res.outro,
                      'proxyHeaders': {
                        'request': res.headers,
                      },
                    },
                  ),
                );
              }
            }
          }).catchError((e) {
            if (kDebugMode) debugPrint('[動漫Scraper] TryEmbed ($cat) error: $e');
          }),
        );
      }

      // 4. AniDB Provider (Sub & Dub)
      if (titleCandidates.isNotEmpty) {
        for (final cat in cats) {
          tasks.add(
            _aniDb
                .extract(
              titleCandidates: titleCandidates,
              episodeNumber: episodeNumber,
              category: cat,
            )
                .then((res) {
              if (res != null &&
                  res.url.isNotEmpty &&
                  seenUrls.add(res.url) &&
                  !controller.isClosed) {
                final catUpper = cat.toUpperCase();
                controller.add(
                  StreamSource(
                    name: '⚡ AniDB • $catUpper',
                    title:
                        '${anime.displayTitle} • Ep $episodeNumber [AniDB • $catUpper]',
                    description:
                        'AniDB • Master HLS • $catUpper',
                    url: res.url,
                    addonName: 'AniDB',
                    headers: res.headers,
                    behaviorHints: {
                      'notWebReady': false,
                      'proxyHeaders': {
                        'request': res.headers,
                      },
                    },
                  ),
                );
              }
            }).catchError((e) {
              if (kDebugMode) debugPrint('[動漫Scraper] AniDB ($cat) error: $e');
            }),
          );
        }
      }

      // 5. Fallback Hentai extractors for NSFW/Ecchi anime
      final isAdult = anime.genres.any((g) =>
          g.toLowerCase().contains('hentai') ||
          g.toLowerCase().contains('erotica') ||
          g.toLowerCase().contains('ecchi'));

      if (isAdult && titleCandidates.isNotEmpty) {
        tasks.add(
          _watchHentai.extract(
            titleCandidates: titleCandidates,
            episodeNumber: episodeNumber,
          ).then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              controller.add(
                StreamSource(
                  name: '⚡ 觀看Hentai',
                  title: '${anime.displayTitle} • Ep $episodeNumber [觀看Hentai]',
                  description: '觀看Hentai • Direct MP4',
                  url: res.url,
                  addonName: '觀看Hentai',
                  headers: {
                    'Referer': res.referer,
                    'Origin': res.origin,
                  },
                ),
              );
            }
          }).catchError((_) {}),
        );

        tasks.add(
          _hentaini.extract(
            titleCandidates: titleCandidates,
            episodeNumber: episodeNumber,
          ).then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              controller.add(
                StreamSource(
                  name: '⚡ Hentaini',
                  title: '${anime.displayTitle} • Ep $episodeNumber [Hentaini]',
                  description: 'Hentaini • Direct MP4',
                  url: res.url,
                  addonName: 'Hentaini',
                  headers: {
                    'Referer': res.referer,
                    'Origin': res.origin,
                  },
                ),
              );
            }
          }).catchError((_) {}),
        );
      }

      await Future.wait(tasks);
      if (!controller.isClosed) {
        controller.close();
      }
    }();

    return controller.stream;
  }

  /// Scrapes anime streams when only basic metadata (title, anilistId, episodeNumber) is available,
  /// e.g. from in-player sources panel or continuing playback.
  Stream<StreamSource> scrapeStreamsByDetails({
    required String title,
    int? anilistId,
    required int episodeNumber,
    String? categoryFilter,
  }) {
    final controller = StreamController<StreamSource>();
    final seenUrls = <String>{};

    final cleanTitle = cleanAnimeTitle(title);
    final titleCandidates = [
      cleanTitle,
      title,
    ].where((t) => t.trim().isNotEmpty).toSet().toList();

    () async {
      final tasks = <Future>[];
      final cats = categoryFilter != null ? [categoryFilter.toLowerCase()] : ['sub', 'dub'];

      // 1. MegaPlay (if anilistId is available)
      if (anilistId != null && anilistId > 0) {
        for (final cat in cats) {
          tasks.add(
            _megaPlay
                .extract(
              anilistId: anilistId,
              episodeNumber: episodeNumber,
              category: cat,
            )
                .then((res) {
              if (res != null &&
                  res.url.isNotEmpty &&
                  seenUrls.add(res.url) &&
                  !controller.isClosed) {
                final catUpper = cat.toUpperCase();
                final subCount = res.tracks.where((t) => t.kind != 'thumbnails').length;
                final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

                controller.add(
                  StreamSource(
                    name: '⚡ Mega播放 • $catUpper',
                    title: '$cleanTitle • Ep $episodeNumber [Mega播放 • $catUpper]',
                    description: 'Mega播放 • Master HLS • $catUpper$subLabel',
                    url: res.url,
                    addonName: 'Mega播放',
                    headers: res.headers,
                    behaviorHints: {
                      'notWebReady': false,
                      if (res.intro != null) 'intro': res.intro,
                      if (res.outro != null) 'outro': res.outro,
                      'proxyHeaders': {
                        'request': res.headers,
                      },
                    },
                  ),
                );
              }
            }).catchError((e) {
              if (kDebugMode) debugPrint('[動漫Scraper] In-player Mega播放 error: $e');
            }),
          );
        }

        // 2. ReCloud Provider (Sub & Dub)
        for (final cat in cats) {
          tasks.add(
            _reCloud
                .extract(
              anilistId: anilistId,
              episodeNumber: episodeNumber,
              category: cat,
            )
                .then((res) {
              if (res != null &&
                  res.url.isNotEmpty &&
                  seenUrls.add(res.url) &&
                  !controller.isClosed) {
                final catUpper = cat.toUpperCase();
                final subCount = res.tracks.where((t) => t.kind != 'thumbnails').length;
                final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

                controller.add(
                  StreamSource(
                    name: '⚡ ReCloud • $catUpper',
                    title: '$cleanTitle • Ep $episodeNumber [ReCloud • $catUpper]',
                    description: 'ReCloud • Master HLS • $catUpper$subLabel',
                    url: res.url,
                    addonName: 'ReCloud',
                    headers: res.headers,
                    behaviorHints: {
                      'notWebReady': true,
                      if (res.intro != null) 'intro': res.intro,
                      if (res.outro != null) 'outro': res.outro,
                      'proxyHeaders': {
                        'request': res.headers,
                      },
                    },
                  ),
                );
              }
            }).catchError((e) {
              if (kDebugMode) debugPrint('[動漫Scraper] In-player ReCloud error: $e');
            }),
          );
        }

        // 3. TryEmbed Provider (Sub & Dub)
        for (final cat in cats) {
          tasks.add(
            _tryEmbed
                .extractAll(
              anilistId: anilistId,
              episodeNumber: episodeNumber,
              category: cat,
            )
                .then((results) {
              for (final res in results) {
                if (res.url.isNotEmpty &&
                    seenUrls.add(res.url) &&
                    !controller.isClosed) {
                  final catUpper = cat.toUpperCase();
                  final subCount = res.tracks.length;
                  final subLabel = subCount > 0 ? ' • $subCount 字幕' : '';

                  controller.add(
                    StreamSource(
                      name: '⚡ TryEmbed • ${res.serverName} • $catUpper',
                      title: '$cleanTitle • Ep $episodeNumber [TryEmbed • ${res.serverName} • $catUpper]',
                      description: 'TryEmbed (${res.serverName}) • Master HLS • $catUpper$subLabel',
                      url: res.url,
                      addonName: 'TryEmbed',
                      headers: res.headers,
                      behaviorHints: {
                        'notWebReady': false,
                        if (res.intro != null) 'intro': res.intro,
                        if (res.outro != null) 'outro': res.outro,
                        'proxyHeaders': {
                          'request': res.headers,
                        },
                      },
                    ),
                  );
                }
              }
            }).catchError((e) {
              if (kDebugMode) debugPrint('[動漫Scraper] In-player TryEmbed error: $e');
            }),
          );
        }
      }

      // 4. AniDB Provider (Sub & Dub)
      if (titleCandidates.isNotEmpty) {
        for (final cat in cats) {
          tasks.add(
            _aniDb
                .extract(
              titleCandidates: titleCandidates,
              episodeNumber: episodeNumber,
              category: cat,
            )
                .then((res) {
              if (res != null &&
                  res.url.isNotEmpty &&
                  seenUrls.add(res.url) &&
                  !controller.isClosed) {
                final catUpper = cat.toUpperCase();
                controller.add(
                  StreamSource(
                    name: '⚡ AniDB • $catUpper',
                    title: '$cleanTitle • Ep $episodeNumber [AniDB • $catUpper]',
                    description: 'AniDB • Master HLS • $catUpper',
                    url: res.url,
                    addonName: 'AniDB',
                    headers: res.headers,
                    behaviorHints: {
                      'notWebReady': false,
                      'proxyHeaders': {
                        'request': res.headers,
                      },
                    },
                  ),
                );
              }
            }).catchError((e) {
              if (kDebugMode) debugPrint('[動漫Scraper] In-player AniDB error: $e');
            }),
          );
        }
      }

      // 3. Fallback Hentai extractors
      if (titleCandidates.isNotEmpty) {
        tasks.add(
          _watchHentai.extract(
            titleCandidates: titleCandidates,
            episodeNumber: episodeNumber,
          ).then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              controller.add(
                StreamSource(
                  name: '⚡ 觀看Hentai',
                  title: '$cleanTitle • Ep $episodeNumber [觀看Hentai]',
                  description: '觀看Hentai • Direct MP4',
                  url: res.url,
                  addonName: '觀看Hentai',
                  headers: {
                    'Referer': res.referer,
                    'Origin': res.origin,
                  },
                ),
              );
            }
          }).catchError((_) {}),
        );

        tasks.add(
          _hentaini.extract(
            titleCandidates: titleCandidates,
            episodeNumber: episodeNumber,
          ).then((res) {
            if (res != null &&
                res.url.isNotEmpty &&
                seenUrls.add(res.url) &&
                !controller.isClosed) {
              controller.add(
                StreamSource(
                  name: '⚡ Hentaini',
                  title: '$cleanTitle • Ep $episodeNumber [Hentaini]',
                  description: 'Hentaini • Direct MP4',
                  url: res.url,
                  addonName: 'Hentaini',
                  headers: {
                    'Referer': res.referer,
                    'Origin': res.origin,
                  },
                ),
              );
            }
          }).catchError((_) {}),
        );
      }

      await Future.wait(tasks);
      if (!controller.isClosed) {
        controller.close();
      }
    }();

    return controller.stream;
  }

  /// Fetch all scraped stream sources as a list
  Future<List<StreamSource>> scrapeAllStreams({
    required AnimeMedia anime,
    required int episodeNumber,
    String? categoryFilter,
  }) async {
    final list = <StreamSource>[];
    await for (final source in scrapeStreamsStream(
      anime: anime,
      episodeNumber: episodeNumber,
      categoryFilter: categoryFilter,
    )) {
      list.add(source);
    }
    return list;
  }

  /// Converts AnimeMedia and Episode to MovieDetail and Video for the PlayerScreen
  static MovieDetail toMovieDetail(
    AnimeMedia anime, {
    List<AniDbEpisode>? aniDbEpisodes,
    int? customEpisodeCount,
  }) {
    int totalCount = (aniDbEpisodes != null && aniDbEpisodes.isNotEmpty)
        ? aniDbEpisodes.length
        : (customEpisodeCount != null && customEpisodeCount > 0)
            ? customEpisodeCount
            : (anime.totalEpisodes > 0)
                ? anime.totalEpisodes
                : (anime.nextAiring != null && anime.nextAiring!.episode > 1)
                    ? anime.nextAiring!.episode - 1
                    : (anime.format.toUpperCase() == 'MOVIE'
                        ? 1
                        : (anime.status.toUpperCase() == 'RELEASING' ? 1200 : 24));

    final List<Video> videos;
    if (aniDbEpisodes != null && aniDbEpisodes.isNotEmpty) {
      videos = List.generate(aniDbEpisodes.length, (i) {
        final ep = aniDbEpisodes[i];
        return Video(
          id: 'anilist:${anime.id}:${ep.number}',
          season: 1,
          episode: ep.number,
          title: '集 ${ep.number}',
          thumbnail: anime.backdropUrl,
        );
      });
    } else {
      videos = List.generate(
        totalCount,
        (i) => Video(
          id: 'anilist:${anime.id}:${i + 1}',
          season: 1,
          episode: i + 1,
          title: '集 ${i + 1}',
          thumbnail: anime.backdropUrl,
        ),
      );
    }

    return MovieDetail(
      id: 'anilist:${anime.id}',
      type: 'anime',
      name: anime.displayTitle,
      poster: anime.coverUrl,
      background: anime.backdropUrl,
      description: anime.description,
      year: anime.seasonYear > 0 ? '${anime.season年份}' : null,
      imdbRating: anime.averageScore > 0 ? anime.formattedScore : null,
      genres: anime.genres,
      videos: videos,
    );
  }

  static Video toVideo(AnimeMedia anime, int episodeNumber, {String? title, String? thumbnail}) {
    return Video(
      id: 'anilist:${anime.id}:$episodeNumber',
      season: 1,
      episode: episodeNumber,
      title: (title != null && title.isNotEmpty) ? title : '集 $episodeNumber',
      thumbnail: (thumbnail != null && thumbnail.isNotEmpty) ? thumbnail : anime.backdropUrl,
    );
  }
}
