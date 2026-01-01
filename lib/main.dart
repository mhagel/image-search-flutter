import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Search',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Image Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // photos returned from the API (appended as we paginate)
  List<dynamic> _photos = [];
  String _query = '';
  Timer? _debounce;

  // pagination & loading state
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _perPage = 5;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // when the user scrolls near the bottom, try loading next page
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          fetchData();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch one page of results and append them to _photos. When page==1 we
  // replace the results (used for new searches).
  Future<void> fetchData() async {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _photos = [];
        _hasMore = true;
        _page = 1;
      });
      return;
    }

    if (_isLoading) return;
    _isLoading = true;

    // Leaving this here for demo purposes
    final apiKey = '9TFgGLiRjlVExyhQBHmhdkruSkFUoa87w1SlwbuhRRAzGHDhYdq7auea';
    final uri = Uri.https('api.pexels.com', '/v1/search', {
      'query': trimmed,
      'per_page': '$_perPage',
      'page': '$_page',
    });

    try {
      final response = await http.get(uri, headers: {'Authorization': apiKey});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> fetched = data['photos'] ?? [];

        setState(() {
          if (_page == 1) {
            _photos = fetched;
          } else {
            _photos.addAll(fetched);
          }

          // If we received fewer than requested, there are no more pages.
          if (fetched.length < _perPage) {
            _hasMore = false;
          } else {
            _page += 1;
          }
        });
      } else {
        // non-200
        print('Request failed (${response.statusCode}): ${response.body}');
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      print('Error fetching images: $e');
      setState(() {
        _hasMore = false;
      });
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Search query',
                ),
                onChanged: (value) {
                  // clear previous results immediately when the query changes
                  // and reset pagination; wait 3s of inactivity before fetching
                  _debounce?.cancel();
                  setState(() {
                    _query = value;
                    _photos = [];
                    _hasMore = true;
                    _page = 1;
                  });

                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    if (!mounted) return;
                    fetchData();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // show images in a list with infinite scroll
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                // include an extra item for the loading indicator when more pages exist
                itemCount: _photos.length + (_hasMore && _isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _photos.length) {
                    final photo = _photos[index];
                    return Image.network(photo['src']['medium']);
                  }

                  // loading indicator row
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
