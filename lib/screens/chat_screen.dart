import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String getChatRoomId(String a, String b) {
    return (a.compareTo(b) > 0) ? "${b}_$a" : "${a}_$b";
  }

  void sendMessage() async {
    if (_msgController.text.trim().isEmpty || currentUser == null) return;
    
    String text = _msgController.text.trim();
    _msgController.clear(); 

    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return 'غير متصل';
    DateTime dt = timestamp.toDate();
    // تنسيق بسيط للساعة والدقيقة
    return 'آخر ظهور: ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold();
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Text(widget.receiverName);
            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) return Text(widget.receiverName);

            bool isOnline = userData['isOnline'] ?? false;
            Timestamp? lastSeen = userData['lastSeen'] as Timestamp?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  isOnline ? 'متصل الآن' : formatLastSeen(lastSeen),
                  style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.grey, fontSize: 12),
                )
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('ابدأ المحادثة الآن! 💬', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  reverse: true, 
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var msg = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentUser!.uid; 
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.purpleAccent : const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: Radius.circular(isMe ? 15 : 0), bottomRight: Radius.circular(isMe ? 0 : 15)),
                        ),
                        child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16), textDirection: TextDirection.rtl),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0), color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.send, color: Colors.purpleAccent), onPressed: sendMessage),
                Expanded(
                  child: TextField(
                    controller: _msgController, textDirection: TextDirection.rtl,
                    decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: const TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFF2A2A3E), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
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
