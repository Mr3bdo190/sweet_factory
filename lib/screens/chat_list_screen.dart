import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A1A2E), elevation: 0, centerTitle: true),
      body: currentUser == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('مفيش مستخدمين لسه.', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var userDoc = snapshot.data!.docs[index];
                    var user = userDoc.data() as Map<String, dynamic>? ?? {};
                    
                    // الحماية السحرية: هنجيب الـ ID من اسم المستند نفسه (مستحيل يكون Null)
                    String uid = userDoc.id; 
                    if (uid == currentUser.uid) return const SizedBox.shrink(); 
                    
                    bool isOnline = user['isOnline'] == true;
                    String name = user['name']?.toString() ?? 'مستخدم';
                    String email = user['email']?.toString() ?? '';
                    String profilePic = user['profilePic']?.toString() ?? '';

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.purpleAccent, 
                            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                            child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null
                          ),
                          if (isOnline) 
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1A2E), width: 2))),
                            )
                        ],
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.purpleAccent, size: 20),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: uid, receiverName: name)));
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
