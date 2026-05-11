import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  void postComment() async {
    if (_commentController.text.trim().isEmpty || user == null) return;

    try {
      String text = _commentController.text.trim();
      _commentController.clear();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String username = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';

      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
        'uid': user!.uid,
        'username': username,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      DocumentSnapshot postDoc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      String postOwnerId = (postDoc.data() as Map<String, dynamic>)['uid'];

      if (postOwnerId != user!.uid) {
        await FirebaseFirestore.instance.collection('users').doc(postOwnerId).collection('notifications').add({
          'title': 'تعليق جديد 💬',
          'body': 'قام $username بالتعليق على منشورك: "$text"',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التعليقات', style: TextStyle(color: Colors.purpleAccent)), backgroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('كن أول من يعلق!', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var commentDoc = snapshot.data!.docs[index];
                    var comment = commentDoc.data() as Map<String, dynamic>;
                    bool isMyComment = user != null && comment['uid'] == user!.uid;

                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, radius: 16, child: Icon(Icons.person, color: Colors.white, size: 20)),
                      title: Text(comment['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(comment['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      trailing: isMyComment 
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').doc(commentDoc.id).delete();
                            },
                          ) 
                        : null,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.send, color: Colors.purpleAccent), onPressed: postComment),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك هنا...', hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true, fillColor: const Color(0xFF2A2A3E), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
