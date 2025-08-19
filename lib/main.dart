import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'movie.dart';
import 'tmdb_api.dart';
import 'db_helper.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const OTTApp());

class OTTApp extends StatelessWidget {
  const OTTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OTT App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TMDBService api = TMDBService();
  final DBHelper dbHelper = DBHelper();
  late Future<List<Movie>> movies;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    movies = fetchMovies();
  }

  Future<List<Movie>> fetchMovies() async {
    final result = await api.fetchPopularMovies();
    return result.map((json) => Movie.fromJson(json)).toList();
  }

  Future<void> searchMovies(String query) async {
    final result = await api.searchMovies(query);
    setState(() {
      movies = Future.value(
        result.map((json) => Movie.fromJson(json)).toList(),
      );
    });
  }

  Future<void> playTrailer(String youtubeKey) async {
    final url = 'https://www.youtube.com/watch?v=$youtubeKey';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open trailer")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "LetsOTT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.redAccent,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search movies...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => searchMovies(searchController.text),
                ),
              ),
            ),
          ),

          // Movie Sections
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: movies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No movies found"));
                } else {
                  final movieList = snapshot.data!;
                  return ListView(
                    children: [
                      // Featured Banner
                      _buildFeaturedBanner(movieList[0]),

                      // Horizontal Sections
                      _buildMovieSection("Popular Movies", movieList),
                      _buildMovieSection("Trending Now", movieList),
                      _buildMovieSection("Top Rated", movieList),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Featured Banner
  Widget _buildFeaturedBanner(Movie movie) {
    return GestureDetector(
      onTap: () async {
        final trailerKey = await api.fetchTrailer(movie.id);
        if (trailerKey != null) playTrailer(trailerKey);
      },
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: api.getImageUrl(movie.backdropPath ?? movie.posterPath),
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.4)),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  final key = await api.fetchTrailer(movie.id);
                  if (key != null) playTrailer(key);
                },
                child: const Text("WatchNow"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal Movie Section
  Widget _buildMovieSection(String title, List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return FutureBuilder<bool>(
                future: dbHelper.isFavorite(movie.id),
                builder: (context, favSnapshot) {
                  final isFav = favSnapshot.data ?? false;
                  return GestureDetector(
                    onTap: () async {
                      final trailerKey = await api.fetchTrailer(movie.id);
                      if (trailerKey != null) playTrailer(trailerKey);
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: api.getImageUrl(movie.posterPath),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      if (isFav) {
                                        await dbHelper.removeFavorite(movie.id);
                                      } else {
                                        await dbHelper.insertFavorite(movie);
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
