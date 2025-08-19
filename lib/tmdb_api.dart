import 'dart:convert';
import 'package:http/http.dart' as http;

const String tmdbApiKey = "df295c7a42169edeade5e97c2ab75021";

class TMDBService {
  final String baseUrl = "https://api.themoviedb.org/3";

  Future<List> fetchPopularMovies() async {
    final response = await http.get(
      Uri.parse("$baseUrl/movie/popular?api_key=$tmdbApiKey&language=en-US&page=1"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception("Failed to load movies");
    }
  }

  Future<List> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/search/movie?api_key=$tmdbApiKey&language=en-US&query=$query&page=1"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception("Failed to search movies");
    }
  }

  Future<String?> fetchTrailer(int movieId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/movie/$movieId/videos?api_key=$tmdbApiKey&language=en-US"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      final trailer = results.firstWhere(
        (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
        orElse: () => null,
      );
      return trailer != null ? trailer['key'] : null;
    } else {
      return null;
    }
  }

  String getImageUrl(String path) {
    return "https://image.tmdb.org/t/p/w500$path";
  }
}
