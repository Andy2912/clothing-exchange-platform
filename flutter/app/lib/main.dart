import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? imageBytes;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchImage();
  }

  Future<void> fetchImage() async {
    try {
      final res = await http.get(Uri.parse("http://10.0.2.2:8000/photo"));
      if (res.statusCode != 200) {
        setState(() => error = "API error: ${res.statusCode}");
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      var base64Str = data["image"] as String;

      // extra safe: remove whitespace/newlines
      base64Str = base64Str.replaceAll('\n', '').replaceAll('\r', '').trim();

      setState(() {
        imageBytes = base64Decode(base64Str);
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Flutter API Test (Base64)",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: fetchImage,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Hello world!",
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red))
            else if (imageBytes == null)
              const CircularProgressIndicator()
            else
              Image.memory(imageBytes!, height: 250),
          ],
        ),
      ),
    );
  }
}