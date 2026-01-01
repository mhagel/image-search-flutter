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
  Map<String, dynamic> _images = {};
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void fetchData() async {
    final apiKey = '9TFgGLiRjlVExyhQBHmhdkruSkFUoa87w1SlwbuhRRAzGHDhYdq7auea';

    final httpPackageUrl = Uri.https('api.pexels.com', 'v1/search', {
      'query': _query,
      'per_page': '5',
    });
    final httpPackageInfo = await http.read(
      httpPackageUrl,
      headers: {'Authorization': apiKey},
    );
    final httpPackageJson =
        json.decode(httpPackageInfo) as Map<String, dynamic>;
    print(httpPackageJson);

    setState(() {
      _images = httpPackageJson;
    });
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
                  _query = value;
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    if (!mounted) return;
                    fetchData();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // show images in a list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _images['photos']?.length ?? 0,
                itemBuilder: (context, index) {
                  final photo = _images['photos'][index];
                  return Image.network(photo['src']['medium']);
                },
                separatorBuilder: (context, index) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
