import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatViewer extends StatelessWidget {
  final String chatRoomId;
  final String user1;
  final String user2;
  const AdminChatViewer({super.key, required this.chatRoomId, required this.user1, required this.user2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مراقبة: $user1 و $user2', style: const TextStyle(fontSize: 14, color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.5),
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد رسائل بينهم', style: TextStyle(color: Colors.grey)));
          
          return ListView.builder(
            reverse: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var msg = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String text = msg['text'] ?? '';
              String imageUrl = msg['imageUrl'] ?? '';
              bool isRead = msg['isRead'] == true;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty) Image.network(imageUrl, height: 150),
                    if (text.isNotEmpty) Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(isRead ? 'قُرئت' : 'لم تُقرأ', style: TextStyle(color: isRead ? Colors.blueAccent : Colors.grey, fontSize: 12)),
                        const SizedBox(width: 5),
                        Icon(isRead ? Icons.done_all : Icons.check, color: isRead ? Colors.blueAccent : Colors.grey, size: 16),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
