import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comments_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 365) return 'منذ ${(diff.inDays / 365).floor()} سنة';
    if (diff.inDays > 30) return 'منذ ${(diff.inDays / 30).floor()} شهر';
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wateny', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent, fontSize: 24, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen()))),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.purpleAccent,
        backgroundColor: const Color(0xFF1A1A2E),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            // شريط الحالات (Stories)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6, // داتا مؤقتة للحالات
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.purpleAccent,
                          child: index == 0 ? const Icon(Icons.add, color: Colors.white, size: 30) : const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(index == 0 ? 'إضافة حالة' : 'صديق', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            // قائمة البوستات
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('مفيش بوستات لسه.. خليك أول واحد يكتب!', style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var postDoc = snapshot.data!.docs[index];
                      var post = postDoc.data() as Map<String, dynamic>? ?? {};
                      
                      String postId = postDoc.id;
                      String postOwnerId = post['uid']?.toString() ?? '';
                      String postText = post['text']?.toString() ?? '';
                      String postImageUrl = post['imageUrl']?.toString() ?? '';
                      
                      List likes = (post['likes'] is List) ? post['likes'] : [];
                      bool isLiked = currentUser != null && likes.contains(currentUser.uid);
                      
                      List savedBy = (post['savedBy'] is List) ? post['savedBy'] : [];
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
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(postOwnerId).get(),
                                builder: (context, userSnapshot) {
                                  String displayName = post['username']?.toString() ?? 'مستخدم';
                                  String profilePic = '';
                                  bool isOnline = false;

                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    var uData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                                    displayName = uData['name']?.toString() ?? displayName;
                                    profilePic = uData['profilePic']?.toString() ?? '';
                                    isOnline = uData['isOnline'] == true;
                                  }

                                  return Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                                            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                            child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.purpleAccent) : null,
                                          ),
                                          if (isOnline)
                                            Positioned(
                                              bottom: 0, right: 0,
                                              child: Container(
                                                width: 12, height: 12,
                                                decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1A2E), width: 2)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Text(timeAgo(post['timestamp'] as Timestamp?), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              if (postText.isNotEmpty) Text(postText, style: const TextStyle(fontSize: 15, height: 1.4), textDirection: TextDirection.rtl),
                              if (postImageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(postImageUrl, fit: BoxFit.cover, width: double.infinity, height: 250),
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
                                          }
                                        },
                                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 22),
                                        label: Text('${likes.length}', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId))),
                                        icon: const Icon(Icons.comment_outlined, color: Colors.grey, size: 22),
                                        label: const Text('تعليق', style: TextStyle(color: Colors.grey)),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.purpleAccent : Colors.grey, size: 22),
                                    onPressed: () async {
                                      if (currentUser == null) return;
                                      if (isSaved) {
                                        await FirebaseFirestore.instance.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayRemove([currentUser.uid])});
                                      } else {
                                        await FirebaseFirestore.instance.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayUnion([currentUser.uid])});
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
            ),
          ],
        ),
      ),
    );
  }
}
// Forced Update to trigger Actions
