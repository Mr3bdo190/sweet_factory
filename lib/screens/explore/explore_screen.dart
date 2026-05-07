import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../profile/profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: GlassTheme.textPrimary),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: GlassTheme.textSecondary),
                    hintText: 'Search for users or #hashtags',
                    hintStyle: TextStyle(color: GlassTheme.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _searchQuery.isEmpty
                  ? StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').limit(10).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final users = snapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text('Suggested Users 🔥', style: TextStyle(color: GlassTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final userDoc = users[index];
                                  final userData = userDoc.data() as Map<String, dynamic>;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: GlassTheme.primaryAccent,
                                      backgroundImage: userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty ? NetworkImage(userData['profileImageUrl']) : null,
                                      child: (userData['profileImageUrl'] == null || userData['profileImageUrl'].toString().isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                                    ),
                                    title: Text(userData['name'] ?? 'User', style: const TextStyle(color: GlassTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    subtitle: const Text('Tap to view profile', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: ProfileScreen(userId: userDoc.id))));
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final users = snapshot.data?.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery);
                        }).toList() ?? [];

                        if (users.isEmpty) {
                          return const Center(child: Text('No results found', style: TextStyle(color: GlassTheme.textSecondary)));
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userDoc = users[index];
                            final userData = userDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: GlassTheme.primaryAccent,
                                backgroundImage: userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty ? NetworkImage(userData['profileImageUrl']) : null,
                                child: (userData['profileImageUrl'] == null || userData['profileImageUrl'].toString().isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              title: Text(userData['name'] ?? 'User', style: const TextStyle(color: GlassTheme.textPrimary, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Tap to view profile', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: ProfileScreen(userId: userDoc.id))));
                              },
                            );
                          },
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
