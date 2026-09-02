class Movie {
  final String id;
  final String name;
  final String? poster;
  final String? year;
  final String type;
  final String addonBaseUrl;
  final String? imdbRating;

  Movie({
    required this.id,
    required this.name,
    this.poster,
    this.year,
    required this.type,
    required this.addonBaseUrl,
    this.imdbRating,
  });

  factory Movie.fromJson(Map<String, dynamic> json, String addonBaseUrl) {
    String? ratingStr;
    if (json['imdbRating'] != null) {
      ratingStr = json['imdbRating'].toString();
    } else if (json['rating'] != null) {
      ratingStr = json['rating'].toString();
    } else if (json['imdb_rating'] != null) {
      ratingStr = json['imdb_rating'].toString();
    } else if (json['vote_average'] != null) {
      ratingStr = json['vote_average'].toString();
    }

    return Movie(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['poster']?.toString(),
      year: json['releaseInfo']?.toString() ?? json['year']?.toString(),
      type: json['type']?.toString() ?? 'movie',
      addonBaseUrl: addonBaseUrl,
      imdbRating: ratingStr,
    );
  }
}
