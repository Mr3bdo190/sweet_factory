import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/wateny_toast.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    if (mounted) WatenyToast.show(context, 'Post Deleted', 'The post has been removed from the platform.', icon: Icons.delete);
  }

  void _toggleBanUser(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': !currentStatus,
    });
    if (mounted) WatenyToast.show(context, 'User Updated', !currentStatus ? 'User banned.' : 'User unbanned.', icon: Icons.gavel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.redAccent,
          unselectedLabelColor: GlassTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.post_add), text: 'Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  final isBanned = user['isBanned'] ?? false;

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].toString().isNotEmpty
                            ? NetworkImage(user['profileImageUrl']) : null,
                        child: (user['profileImageUrl'] == null || user['profileImageUrl'].toString().isEmpty)
                            ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['name'] ?? 'Unknown', style: const TextStyle(color: GlassTheme.textPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email'] ?? '', style: const TextStyle(color: GlassTheme.textSecondary)),
                      trailing: ElevatedButton(
                        onPressed: () => _toggleBanUser(userId, isBanned),
                        style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green : Colors.red),
                        child: Text(isBanned ? 'Unban' : 'Ban', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Posts Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index].data() as Map<String, dynamic>;
                  final postId = posts[index].id;

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Author: ${post['authorName']}', style: const TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(post['content'] ?? '[Media Only]', style: const TextStyle(color: GlassTheme.textPrimary)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _deletePost(postId),
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            label: const Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
