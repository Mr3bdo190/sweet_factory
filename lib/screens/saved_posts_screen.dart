import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comments_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('العناصر المحفوظة', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // هنا السر: بنجيب البوستات اللي الـ ID بتاعي جوه مصفوفة savedBy بتاعتها
        stream: FirebaseFirestore.instance.collection('posts').where('savedBy', arrayContains: currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لم تقم بحفظ أي منشورات بعد.', style: TextStyle(color: Colors.grey)));

          var posts = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
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
                              const CircleAvatar(backgroundColor: Colors.purpleAccent, radius: 15, child: Icon(Icons.person, size: 15, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(post['username'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          // زرار إزالة الحفظ من الشاشة دي مباشرة
                          IconButton(
                            icon: const Icon(Icons.bookmark, color: Colors.purpleAccent, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                                'savedBy': FieldValue.arrayRemove([currentUser.uid])
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.white), textDirection: TextDirection.rtl),
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
          );
        },
      ),
    );
  }
}
