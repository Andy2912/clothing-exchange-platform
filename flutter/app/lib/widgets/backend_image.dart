import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class BackendImage extends StatelessWidget {
  const BackendImage({super.key});

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  Future<Uint8List> _fetchBytes() async {
    final res = await http.get(Uri.parse('$_baseUrl/photo'));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);

    // pas deze key aan als jouw JSON anders is:
    // vb: {"base64": "..."} of {"image": "..."} of {"data": "..."}
    final b64 = (data['base64'] ?? data['image'] ?? data['data']) as String;

    // als backend "data:image/jpeg;base64,...." terugstuurt → prefix weg
    final cleaned = b64.contains(',') ? b64.split(',').last : b64;

    return base64Decode(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _fetchBytes(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Image error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }
}
