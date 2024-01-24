import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:omdb_api_with_streams/models/movie_model.dart';
import 'package:omdb_api_with_streams/utility/constants.dart';
import 'package:http/http.dart' as http;

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  late StreamController _streamController;
  late Stream _stream;
  MovieModel? movie;
  late TextEditingController movieNameController;

  @override
  void initState() {
    super.initState();
    movieNameController = TextEditingController();
    _streamController = StreamController();
    _stream = _streamController.stream;
  }

  @override
  dispose() {
    _streamController.close();
    movieNameController.dispose();
    super.dispose();
  }

  getMovieDetails({required String movieName}) async {
    String url = 'https://www.omdbapi.com/?t=$movieName&apikey=94e188aa';

    _streamController.add(LOADING);

    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['Response'] == 'True') {
        movie = MovieModel.fromJson(jsonResponse);

        _streamController.add(DONE);
      } else {
        _streamController.add(NOT_FOUND);
      }
    } else {
      _streamController.add(ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: movieNameController,
              decoration: const InputDecoration(
                hintText: 'Write a movie name',
                border: OutlineInputBorder(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    movieNameController.clear();
                    _streamController.add(INITIAL);
                    movie = null;
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Clear'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    String movieName = movieNameController.text.trim();
                    if (movieName.isEmpty) {
                      Fluttertoast.showToast(msg: 'Please provide movie name');
                    }

                    getMovieDetails(movieName: movieName);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: StreamBuilder(
                  stream: _stream,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.data == INITIAL) {
                      return const Center(
                        child: Text('Write a movie name'),
                      );
                    }

                    if (snapshot.data == LOADING) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data == NOT_FOUND) {
                      return const Center(
                        child: Text('Movie Not Found'),
                      );
                    }

                    if (snapshot.data == ERROR) {
                      return const Center(
                        child: Text('Something went wrong'),
                      );
                    }

                    if (snapshot.data == DONE) {
                      if (movie != null) {
                        return MovieWidget(movie: movie!);
                      }
                    }

                    return Container();
                  }),
            )
          ],
        ),
      ),
    );
  }
}

class MovieWidget extends StatelessWidget {
  final MovieModel movie;
  const MovieWidget({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Image.network(
          movie.poster!,
          width: 200,
          height: 400,
        ),
        ItemWidget(title: 'Title', value: movie.title!),
        ItemWidget(title: 'Actors', value: movie.actors!),
      ],
    );
  }
}

class ItemWidget extends StatelessWidget {
  final String title;
  final String value;

  const ItemWidget({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Text(
          title,
          style: const TextStyle(color: Colors.purple, fontSize: 18),
        ),
        const Divider(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
      ]),
    );
  }
}
