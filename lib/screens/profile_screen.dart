import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'comments_screen.dart';
import 'saved_posts_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text('الرجاء تسجيل الدخول')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async => await AuthService().logOut(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('خطأ في تحميل البيانات'));
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          List followers = userData['followers'] ?? [];
          List following = userData['following'] ?? [];
          String? profilePic = userData['profilePic'];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purpleAccent,
                      backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                      child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(userData['name'] ?? 'مستخدم', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(userData['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    if (userData['bio'] != null && userData['bio'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(userData['bio'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                      ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('منشورات', '...'), 
                        _buildStatItem('متابعون', followers.length.toString()),
                        _buildStatItem('أتابع', following.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                              child: const Text('تعديل الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.purpleAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPostsScreen())),
                              icon: const Icon(Icons.bookmark, color: Colors.purpleAccent, size: 18),
                              label: const Text('المنشورات المحفوظة', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.grey, thickness: 0.5),
                  ],
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: currentUser.uid).snapshots(),
                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  var posts = postSnapshot.data!.docs;
                  if (posts.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لا توجد منشورات بعد.', style: TextStyle(color: Colors.grey)))));
                  }

                  posts.sort((a, b) {
                    Timestamp? t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    Timestamp? t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    if (t1 == null || t2 == null) return 0;
                    return t2.compareTo(t1);
                  });

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var post = posts[index].data() as Map<String, dynamic>;
                        String postId = posts[index].id;
                        List likes = post['likes'] ?? [];
                        bool isLiked = likes.contains(currentUser.uid);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.purpleAccent, 
                                          radius: 15, 
                                          backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                                          child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 15, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(post['username'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => FirebaseFirestore.instance.collection('posts').doc(postId).delete(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.white), textDirection: TextDirection.rtl),
                                if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(post['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: 250),
                                    ),
                                  ),
                                const Divider(color: Colors.grey, height: 24),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId))),
                                      icon: const Icon(Icons.comment_outlined, color: Colors.grey, size: 20),
                                      label: const Text('تعليق', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        if (isLiked) {
                                          await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayRemove([currentUser.uid])});
                                        } else {
                                          await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayUnion([currentUser.uid])});
                                        }
                                      },
                                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 20),
                                      label: Text('${likes.length}', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: posts.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}
