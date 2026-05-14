import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_chat_viewer.dart';

class AdminUserChats extends StatelessWidget {
  final String targetUid;
  final String targetName;
  const AdminUserChats({super.key, required this.targetUid, required this.targetName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محادثات: $targetName', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1A1A2E)),
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var otherUser = snapshot.data!.docs[index];
              if (otherUser.id == targetUid) return const SizedBox(); // نخفي حسابه من اللستة
              
              var data = otherUser.data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, color: Colors.white)),
                title: Text(data['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white)),
                subtitle: const Text('اضغط لرؤية الدردشة بينهم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.remove_red_eye, color: Colors.redAccent),
                onTap: () {
                  // توليد ID الشات بين الطرفين
                  String chatRoomId = (targetUid.compareTo(otherUser.id) > 0) ? "${otherUser.id}_$targetUid" : "${targetUid}_${otherUser.id}";
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdminChatViewer(chatRoomId: chatRoomId, user1: targetName, user2: data['name'] ?? 'مستخدم')));
                },
              );
            },
          );
        },
      ),
    );
  }
}
