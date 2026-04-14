import 'dart:convert';
import 'package:app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import '../models/match_item.dart';
import '../widgets/app_bottom_nav.dart';



class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

@override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchItem> matches = [];
  bool isLoading = true;

  String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  Future<void> fetchMatches() async {
    final baseUrl = _getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/matches/1'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        matches = data.map((item) => MatchItem.fromJson(item)).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load matches');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
       body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
              ? const Center(
                  child: Text(
                    'No matches yet',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 237, 237, 237),
                        border: Border.all(color: Colors.purple, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage("$baseUrl${match.matchedItemImageUrl}"),
                        ),
                        title: Text(match.otherUsername),
                        subtitle: Text(match.matchedItemName),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Message",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(match_Id: match.matchId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}