import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeWatchStarterPick {
  final String label;
  final String query;
  final String mediaType; // 'movie' or 'tv'
  final String posterPath;

  const WeWatchStarterPick({
    required this.label,
    required this.query,
    required this.mediaType,
    required this.posterPath,
  });

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
}

class WeWatchMediaItem {
  final int tmdbId;
  final String title;
  final String? year;
  final String mediaType; // 'movie' or 'tv'
  final String? posterUrl;
  final String? posterPath;

  WeWatchMediaItem({
    required this.tmdbId,
    required this.title,
    this.year,
    required this.mediaType,
    this.posterUrl,
    this.posterPath,
  });

  factory WeWatchMediaItem.fromJson(Map<String, dynamic> json) {
    return WeWatchMediaItem(
      tmdbId: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      year: json['year']?.toString(),
      mediaType: json['mediaType']?.toString() ?? 'movie',
      posterUrl: json['posterUrl']?.toString(),
      posterPath: json['posterPath']?.toString(),
    );
  }
}

class WeWatchUserPick {
  final String id;
  String title;
  String? year;
  String? sentiment; // 'loved', 'liked', 'meh', 'hated'
  String reason;
  List<String> selectedPills;
  int? tmdbId;
  String? mediaType;
  String? posterUrl;
  String? posterPath;

  WeWatchUserPick({
    required this.id,
    this.title = '',
    this.year,
    this.sentiment,
    this.reason = '',
    List<String>? selectedPills,
    this.tmdbId,
    this.mediaType,
    this.posterUrl,
    this.posterPath,
  }) : selectedPills = selectedPills ?? [];

  bool get isValid => title.trim().isNotEmpty && sentiment != null;

  String buildFinalReason() {
    final pillsStr = selectedPills.join(', ');
    final comment = reason.trim();
    if (pillsStr.isEmpty) return comment;
    if (comment.isEmpty) return pillsStr;
    return '$pillsStr. $comment';
  }
}

class WeWatchRecommendation {
  final String id;
  final String title;
  final String? year;
  final String mediaType; // 'movie' or 'tv'
  final String reasoning;
  final String matchExplanation;
  final int matchConfidence;
  final String? posterUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final double? voteAverage;
  final List<String> genres;
  final int tmdbId;

  WeWatchRecommendation({
    required this.id,
    required this.title,
    this.year,
    required this.mediaType,
    required this.reasoning,
    required this.matchExplanation,
    required this.matchConfidence,
    this.posterUrl,
    this.backdropUrl,
    this.releaseDate,
    this.voteAverage,
    required this.genres,
    required this.tmdbId,
  });
}

class WeWatchService {
  static const String _domain = 'www.wewatch.ai';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  static const List<WeWatchStarterPick> starterPicks = [
    WeWatchStarterPick(
      label: 'The Office',
      query: 'The Office 2005',
      mediaType: 'tv',
      posterPath: '/dg9e5fPRRId8PoBE0F6jl5y85Eu.jpg',
    ),
    WeWatchStarterPick(
      label: 'Breaking Bad',
      query: 'Breaking Bad',
      mediaType: 'tv',
      posterPath: '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
    ),
    WeWatchStarterPick(
      label: 'Stranger Things',
      query: 'Stranger Things',
      mediaType: 'tv',
      posterPath: '/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg',
    ),
    WeWatchStarterPick(
      label: 'Game of Thrones',
      query: 'Game of Thrones',
      mediaType: 'tv',
      posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
    ),
    WeWatchStarterPick(
      label: 'The Dark Knight',
      query: 'The Dark Knight',
      mediaType: 'movie',
      posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    ),
    WeWatchStarterPick(
      label: 'Inception',
      query: 'Inception',
      mediaType: 'movie',
      posterPath: '/xlaY2zyzMfkhk0HSC5VUwzoZPU1.jpg',
    ),
    WeWatchStarterPick(
      label: 'Get Out',
      query: 'Get Out 2017',
      mediaType: 'movie',
      posterPath: '/tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg',
    ),
    WeWatchStarterPick(
      label: 'Titanic',
      query: 'Titanic 1997',
      mediaType: 'movie',
      posterPath: '/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg',
    ),
    WeWatchStarterPick(
      label: 'Friends',
      query: 'Friends 1994',
      mediaType: 'tv',
      posterPath: '/2koX1xLkpTQM4IZebYvKysFW1Nh.jpg',
    ),
    WeWatchStarterPick(
      label: 'Succession',
      query: 'Succession',
      mediaType: 'tv',
      posterPath: '/z0XiwdrCQ9yVIr4O0pxzaAYRxdW.jpg',
    ),
    WeWatchStarterPick(
      label: 'The Bear',
      query: 'The Bear',
      mediaType: 'tv',
      posterPath: '/eKfVzzEazSIjJMrw9ADa2x8ksLz.jpg',
    ),
    WeWatchStarterPick(
      label: 'Parks and Rec',
      query: 'Parks and Recreation',
      mediaType: 'tv',
      posterPath: '/5IOj62y2Eb2ngyYmEn1IJ7bFhzH.jpg',
    ),
    WeWatchStarterPick(
      label: 'The Matrix',
      query: 'The Matrix 1999',
      mediaType: 'movie',
      posterPath: '/p96dm7sCMn4VYAStA6siNz30G1r.jpg',
    ),
    WeWatchStarterPick(
      label: 'Toy Story',
      query: 'Toy Story 1995',
      mediaType: 'movie',
      posterPath: '/uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg',
    ),
    WeWatchStarterPick(
      label: 'Spirited Away',
      query: 'Spirited Away',
      mediaType: 'movie',
      posterPath: '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
    ),
    WeWatchStarterPick(
      label: 'Shawshank',
      query: 'The Shawshank Redemption',
      mediaType: 'movie',
      posterPath: '/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg',
    ),
  ];

  /// Searches WeWatch TMDB catalog for movies/shows matching the query.
  static Future<List<WeWatchMediaItem>> searchMedia(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final res = await http.post(
        Uri.https(_domain, '/onboarding'),
        headers: {
          'Next-Action': '40e1094766c1eb3fac9963001491efec94b7ff8db7',
          'Content-Type': 'text/plain;charset=UTF-8',
          'User-Agent': _userAgent,
          'Origin': 'https://$_domain',
          'Referer': 'https://$_domain/onboarding',
          'Accept': 'text/x-component',
        },
        body: jsonEncode([trimmed]),
      );

      if (res.statusCode == 200) {
        final body = res.body;
        // Parse Next.js RSC payload: 1:[{...}]
        final lineIndex = body.indexOf('1:');
        if (lineIndex != -1) {
          final jsonPart = body.substring(lineIndex + 2).trim();
          final dynamic parsed = jsonDecode(jsonPart);
          if (parsed is List) {
            return parsed
                .map((e) => WeWatchMediaItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[WeWatchService] searchMedia error: $e');
    }
    return [];
  }

  /// Generates dynamic AI reason pills based on the movie and user sentiment.
  static Future<List<String>> generateReasonPills({
    required String title,
    int? year,
    required String sentiment,
    int? tmdbId,
    String? mediaType,
  }) async {
    try {
      final targetObj = (tmdbId != null && tmdbId > 0 && mediaType != null)
          ? {'tmdbId': tmdbId, 'mediaType': mediaType}
          : null;

      final res = await http.post(
        Uri.https(_domain, '/onboarding'),
        headers: {
          'Next-Action': '7855e82fc70f46551293c772a08f6d599df0a69e66',
          'Content-Type': 'text/plain;charset=UTF-8',
          'User-Agent': _userAgent,
          'Origin': 'https://$_domain',
          'Referer': 'https://$_domain/onboarding',
          'Accept': 'text/x-component',
        },
        body: jsonEncode([title, year, sentiment, targetObj]),
      );

      if (res.statusCode == 200) {
        final body = res.body;
        final lineIndex = body.indexOf('1:');
        if (lineIndex != -1) {
          final jsonPart = body.substring(lineIndex + 2).trim();
          final dynamic parsed = jsonDecode(jsonPart);
          if (parsed is Map && parsed['data'] is Map && parsed['data']['pills'] is List) {
            return (parsed['data']['pills'] as List).map((e) => e.toString()).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[WeWatchService] generateReasonPills error: $e');
    }

    // Default fallback pills based on sentiment
    switch (sentiment) {
      case 'loved':
        return [
          'Gripping plot & storytelling',
          'Phenomenal acting & characters',
          'Stunning cinematography & visuals',
          'Unforgettable music & score',
          'Deep emotional connection',
        ];
      case 'liked':
        return [
          'Fun & entertaining pace',
          'Solid performances',
          'Great concept & premise',
          'Good action sequences',
        ];
      case 'meh':
        return [
          'Felt too slow / dragged',
          'Predictable plot',
          'Forgettable ending',
          'Underdeveloped characters',
        ];
      case 'hated':
        return [
          'Poor writing & dialogue',
          'Disappointing conclusion',
          'Boring & unengaging',
        ];
      default:
        return [];
    }
  }

  /// Submits the rated movies and retrieves the AI recommendation list.
  static Future<List<WeWatchRecommendation>> submitAndGetRecommendations(
    List<WeWatchUserPick> picks, {
    String quality = 'fast',
    String? moodGuidance,
  }) async {
    final validPicks = picks.where((p) => p.isValid).toList();
    if (validPicks.isEmpty) return [];

    final moviesPayload = validPicks.map((p) {
      return {
        'id': p.id,
        'title': p.title,
        'sentiment': p.sentiment,
        'reason': p.buildFinalReason(),
        'tmdbMovieId': (p.mediaType == 'movie') ? p.tmdbId : null,
        'tmdbTvId': (p.mediaType == 'tv') ? p.tmdbId : null,
        'mediaType': p.mediaType ?? 'movie',
        'year': p.year ?? '',
        'posterPath': p.posterPath,
      };
    }).toList();

    final bodyJson = jsonEncode({
      'movies': moviesPayload,
      'platforms': [],
      'recommendationQuality': quality,
      'guidance': moodGuidance,
    });

    // 1. Submit movies to initialize session
    final submitRes = await http.post(
      Uri.https(_domain, '/api/internal/onboarding/submit-movies'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': _userAgent,
        'Origin': 'https://$_domain',
        'Referer': 'https://$_domain/onboarding',
        'Accept': 'application/json, text/plain, */*',
      },
      body: bodyJson,
    );

    if (submitRes.statusCode != 200) {
      throw Exception('Failed to submit taste profile (Status: ${submitRes.statusCode})');
    }

    final rawCookies = submitRes.headers['set-cookie'] ?? '';
    final cookiesList = rawCookies.split(',').map((c) => c.split(';')[0].trim()).where((c) => c.isNotEmpty).toList();
    final cookieHeader = cookiesList.join('; ');

    // 2. Fetch recommendations stream with the returned session cookies
    final recRes = await http.get(
      Uri.https(_domain, '/recommendations'),
      headers: {
        'Cookie': cookieHeader,
        'User-Agent': _userAgent,
        'Referer': 'https://$_domain/onboarding',
      },
    );

    if (recRes.statusCode != 200) {
      throw Exception('Failed to load recommendation matches (Status: ${recRes.statusCode})');
    }

    // 3. Extract recommendations from the Next.js RSC stream payload
    return _parseRecommendationsFromRsc(recRes.body);
  }

  static List<WeWatchRecommendation> _parseRecommendationsFromRsc(String html) {
    // Collect next_f push streams
    final regex = RegExp(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)');
    final matches = regex.allMatches(html);
    var allRsc = '';

    for (final m in matches) {
      final chunk = m.group(1);
      if (chunk != null) {
        try {
          allRsc += jsonDecode('"$chunk"') as String;
        } catch (_) {
          allRsc += chunk;
        }
      }
    }

    if (allRsc.isEmpty) {
      allRsc = html;
    }

    final list = <WeWatchRecommendation>[];
    final startRegex = RegExp(
      r'\{"id":"([a-f0-9\-]+)","title":"([^"]+)","tmdb_id":(\d+),"media_type":"([^"]+)"',
    );
    final itemMatches = startRegex.allMatches(allRsc);

    for (final match in itemMatches) {
      final id = match.group(1) ?? '';
      final title = match.group(2) ?? '';
      final tmdbId = int.tryParse(match.group(3) ?? '') ?? 0;
      final mediaType = match.group(4) ?? 'movie';
      final startIdx = match.start;

      final blockEnd = (startIdx + 2200 < allRsc.length) ? startIdx + 2200 : allRsc.length;
      final block = allRsc.substring(startIdx, blockEnd);

      final reasoningMatch = RegExp(r'"reasoning":"([^"]+)"').firstMatch(block);
      final matchExpMatch = RegExp(r'"match_explanation":"([^"]+)"').firstMatch(block);
      final confidenceMatch = RegExp(r'"match_confidence":(\d+)').firstMatch(block);
      final posterMatch = RegExp(r'"posterUrl":"([^"]+)"').firstMatch(block);
      final backdropMatch = RegExp(r'"backdropUrl":"([^"]+)"').firstMatch(block);
      final releaseDateMatch = RegExp(r'"release_date":"([^"]+)"').firstMatch(block);
      final voteAvgMatch = RegExp(r'"vote_average":([0-9.]+)').firstMatch(block);

      List<String> genres = [];
      final genresMatch = RegExp(r'"genres":\[(.*?)\]').firstMatch(block);
      if (genresMatch != null) {
        genres = genresMatch
            .group(1)!
            .split(',')
            .map((g) => g.replaceAll('"', '').trim())
            .where((g) => g.isNotEmpty)
            .toList();
      }

      final relDate = releaseDateMatch?.group(1);
      final yearStr = (relDate != null && relDate.length >= 4) ? relDate.substring(0, 4) : null;

      list.add(WeWatchRecommendation(
        id: id,
        title: title,
        year: yearStr,
        mediaType: mediaType,
        reasoning: reasoningMatch?.group(1) ?? 'Matches your favorite themes and pacing.',
        matchExplanation: matchExpMatch?.group(1) ?? 'Recommended based on your rated favorites.',
        matchConfidence: int.tryParse(confidenceMatch?.group(1) ?? '') ?? 85,
        posterUrl: posterMatch?.group(1),
        backdropUrl: backdropMatch?.group(1),
        releaseDate: relDate,
        voteAverage: double.tryParse(voteAvgMatch?.group(1) ?? ''),
        genres: genres,
        tmdbId: tmdbId,
      ));
    }

    return list;
  }
}
