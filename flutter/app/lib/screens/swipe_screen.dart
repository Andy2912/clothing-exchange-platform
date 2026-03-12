import 'package:flutter/material.dart';
import '../widgets/backend_image.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  static const bgStart = Colors.white;
  static const bgEnd = Color.fromARGB(255, 196, 129, 255);
  static const accent = Color.fromARGB(255, 171, 0, 193);

final items = [
  {
    'name': 'Plaid Flannel Shirt',
    'details': 'Carhartt, Size M. Gently used.',
    'owner': 'by Bruce',
  },
  {
    'name': 'Vintage Denim Jacket',
    'details': 'Levi\'s, Size L. Good condition.',
    'owner': 'by Emma',
  },
  {
    'name': 'Oversized Hoodie',
    'details': 'Nike, Size XL. Like new.',
    'owner': 'by Alex',
  },
];

int currentIndex = 0;
  double dragX = 0;

  void likeItem() {
    print("Liked!");
    setState(() {
      dragX = 0;
      if (currentIndex < items.length - 1) {
      currentIndex++;
    }
    });
  }

  void dislikeItem() {
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
      child: GestureDetector(
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
  child: Transform.rotate( angle: dragX / 500,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: _DemoCard(
        name: items[currentIndex]['name']!,
        details: items[currentIndex]['details']!,
        owner: items[currentIndex]['owner']!,
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
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String name;
  final String details;
  final String owner;

  const _DemoCard({
    required this.name,
    required this.details,
    required this.owner,
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
            child: const BackendImage(),
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