import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/glass_theme.dart';
import '../screens/home/story_viewer_screen.dart';
import '../screens/home/create_story_screen.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = snapshot.data?.docs ?? [];
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1, // +1 for "Add Story" button
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(context);
              }
              final storyDoc = stories[index - 1];
              final story = storyDoc.data() as Map<String, dynamic>;
              return _buildStoryItem(context, story, storyDoc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoryScreen())),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GlassTheme.primaryAccent, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add, color: GlassTheme.primaryAccent, size: 30),
        ),
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, Map<String, dynamic> story, String storyId) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(story: story, storyId: storyId))),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GlassTheme.glassBorder, width: 2),
          image: DecorationImage(
            image: NetworkImage(story['mediaUrl'] ?? 'https://via.placeholder.com/150'), // Fixed: show story image
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(4),
          child: Text(
            story['authorName'] ?? 'User',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
