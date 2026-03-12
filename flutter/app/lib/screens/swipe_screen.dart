import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clothing_item.dart';
import '../widgets/app_bottom_nav.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  static const bgStart = Colors.white;
  static const bgEnd = Color.fromARGB(255, 196, 129, 255);
  static const accent = Color.fromARGB(255, 171, 0, 193);

Future<void> fetchItems() async {
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/items'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    setState(() {
      items = data.map((item) => ClothingItem.fromJson(item)).toList();
      isLoading = false;
    });
  } else {
    throw Exception('Failed to load items');
  }
}

List<ClothingItem> items = [];
bool isLoading = true;

int currentIndex = 0;
  double dragX = 0;

  void likeItem() {
    if (items.isEmpty) return;

    print("Liked!");
    setState(() {
      dragX = 0;
      if (currentIndex < items.length - 1) {
      currentIndex++;
    }
    });
  }

  void dislikeItem() {
    if (items.isEmpty) return;
    print("Disliked!");
    setState(() {
      dragX = 0;
      if (currentIndex < items.length - 1) {
      currentIndex++;
    }
    });
  }

  void handleDragEnd() {
    if (dragX > 100) {
      likeItem();
    } else if (dragX < -100) {
      dislikeItem();
    } else {
      setState(() {
        dragX = 0;
      });
    }
  }

  @override
  void initState() {
  super.initState();
  fetchItems();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Swipe',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout, color: accent),
                    ),
                  ],
                ),
              ),

              // Card area
              Expanded(
  child: Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: isLoading
    ? const Center(child: CircularProgressIndicator())
    : items.isEmpty
        ? const Center(
            child: Text(
              'No items available',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          )
        : GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragX += details.delta.dx;
              });
            },
            onHorizontalDragEnd: (details) {
              handleDragEnd();
            },
            child: Transform.translate(
              offset: Offset(dragX, 0),
              child: Transform.rotate(
                angle: dragX / 500,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _DemoCard(
  name: items[currentIndex].name,
  details:
      '${items[currentIndex].brand}, Size ${items[currentIndex].size}. ${items[currentIndex].conditionRating}.',
  owner: 'from database',
  imageUrl: items[currentIndex].imageUrl,
),

                ),
              ),
            ),
          ),
    ),
  ),
),

              // Buttons row (nog zonder actie)
              Padding(
                padding: const EdgeInsets.only(bottom: 45, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleActionButton(
                      icon: Icons.close,
                      color: Colors.redAccent,
                      onTap: dislikeItem,
                    ),
                    const SizedBox(width: 26),
                    _CircleActionButton(
                      icon: Icons.favorite,
                      color: Colors.green,
                      onTap: likeItem,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String name;
  final String details;
  final String owner;
  final String imageUrl;

  const _DemoCard({
    required this.name,
    required this.details,
    required this.owner,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 14,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias, // belangrijk: rondingen werken ook op de foto
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Foto (placeholder)
          AspectRatio(
  aspectRatio: 3 / 4,
  child: Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return const Center(child: CircularProgressIndicator());
    },
    errorBuilder: (context, error, stackTrace) {
      return const Center(
        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    },
  ),
),

          // Info onderaan
          Padding(
  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        details,
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 8),
      Text(
        owner,
        style: const TextStyle(
          color: Colors.black45,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}