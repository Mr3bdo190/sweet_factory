import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';
import '../profile/profile_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  final String storyId;

  const StoryViewerScreen({super.key, required this.story, required this.storyId});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.pop(context);
        }
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _progressController.stop(),
        onTapUp: (_) => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.story['mediaUrl'] ?? '', 
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 100));
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Colors.grey.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final authorId = widget.story['authorId'];
                          if (authorId != null) {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: ProfileScreen(userId: authorId))));
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: widget.story['authorImage'] != null && widget.story['authorImage'].toString().isNotEmpty
                                  ? NetworkImage(widget.story['authorImage'])
                                  : null,
                              radius: 20,
                              backgroundColor: GlassTheme.primaryAccent,
                              child: (widget.story['authorImage'] == null || widget.story['authorImage'].toString().isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(widget.story['authorName'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
