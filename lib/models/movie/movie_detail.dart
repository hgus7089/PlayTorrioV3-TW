import 'link.dart';
import 'video.dart';

class MovieDetail {
  final String id;
  final String type;
  final String name;
  final String? poster;
  final String? background;
  final String? logo;
  final String? description;
  final String? year;
  final String? imdbRating;
  final List<String> genres;
  final List<String> cast;
  final List<String> director;
  final String? runtime;
  final List<Link> links;
  final List<Video> videos;
  final String? tmdbId;

  MovieDetail({
    required this.id,
    required this.type,
    required this.name,
    this.poster,
    this.background,
    this.logo,
    this.description,
    this.year,
    this.imdbRating,
    this.genres = const [],
    this.cast = const [],
    this.director = const [],
    this.runtime,
    this.links = const [],
    this.videos = const [],
    this.tmdbId,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'movie',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['poster']?.toString(),
      background: json['background']?.toString(),
      logo: json['logo']?.toString(),
      description: json['description']?.toString(),
      year: json['releaseInfo']?.toString() ?? json['year']?.toString(),
      imdbRating: json['imdbRating']?.toString(),
      genres: _parseStringList(json['genres']),
      cast: _parseStringList(json['cast']),
      director: _parseStringList(json['director']),
      runtime: json['runtime']?.toString(),
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => Link.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tmdbId: json['moviedb_id']?.toString(),
    );
  }
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is String) return [value];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
