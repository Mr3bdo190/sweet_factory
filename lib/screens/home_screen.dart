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
                      const Divider(color: Colors.grey, height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId))),
                            icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                            label: const Text('تعليق', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              if (currentUser == null) return;
                              if (isLiked) {
                                // شيل اللايك
                                await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayRemove([currentUser.uid])});
                              } else {
                                // حط اللايك
                                await FirebaseFirestore.instance.collection('posts').doc(postId).update({'likes': FieldValue.arrayUnion([currentUser.uid])});
                                
                                // إرسال إشعار اللايك لصاحب البوست (لو مش أنا اللي عامل لايك لنفسي)
                                if (postOwnerId != currentUser.uid) {
                                  DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
                                  String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';
                                  
                                  await FirebaseFirestore.instance.collection('users').doc(postOwnerId).collection('notifications').add({
                                    'title': 'إعجاب جديد ❤️',
                                    'body': 'أعجب $myName بمنشورك!',
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });
                                }
                              }
                            },
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey),
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
