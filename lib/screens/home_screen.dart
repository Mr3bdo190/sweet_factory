import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comments_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wateny', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('مفيش بوستات لسه.. خليك أول واحد يكتب!', style: TextStyle(fontSize: 18, color: Colors.grey)));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var postDoc = snapshot.data!.docs[index];
              var post = postDoc.data() as Map<String, dynamic>;
              String postId = postDoc.id;
              String postOwnerId = post['uid'] ?? '';
              
              List likes = post['likes'] ?? [];
              bool isLiked = currentUser != null && likes.contains(currentUser.uid);

              // لوجيك الحفظ الجديد
              List savedBy = post['savedBy'] ?? [];
              bool isSaved = currentUser != null && savedBy.contains(currentUser.uid);

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
                        children: [
                          CircleAvatar(backgroundColor: Colors.purpleAccent.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.purpleAccent)),
                          const SizedBox(width: 12),
                          Text(post['username'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post['text'] ?? '', style: const TextStyle(fontSize: 15), textDirection: TextDirection.rtl),
                      if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(post['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: 250),
                          ),
                        ),
                      const Divider(color: Colors.grey, height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  if (currentUser == null) return;
                                  if (isLiked) {
                                    await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayRemove([currentUser.uid])});
                                  } else {
                                    await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayUnion([currentUser.uid])});
                                    if (postOwnerId != currentUser.uid) {
                                      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
                                      String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';
                                      await FirebaseFirestore.instance.collection('users').doc(postOwnerId).collection('notifications').add({
                                        'title': 'إعجاب جديد ❤️', 'body': 'أعجب $myName بمنشورك!', 'timestamp': FieldValue.serverTimestamp(),
                                      });
                                    }
                                  }
                                },
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 20),
                                label: Text('${likes.length}', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId))),
                                icon: const Icon(Icons.comment_outlined, color: Colors.grey, size: 20),
                                label: const Text('تعليق', style: TextStyle(color: Colors.grey)),
                              ),
                            ],
                          ),
                          // زرار الحفظ (Bookmark) على الشمال
                          IconButton(
                            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.purpleAccent : Colors.grey),
                            onPressed: () async {
                              if (currentUser == null) return;
                              if (isSaved) {
                                await FirebaseFirestore.instance.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayRemove([currentUser.uid])});
                              } else {
                                await FirebaseFirestore.instance.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayUnion([currentUser.uid])});
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المنشور 📌', textDirection: TextDirection.rtl), duration: Duration(seconds: 1)));
                              }
                            },
                          )
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
