import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  final Box localChatsBox = Hive.box('local_chats'); 
  
  bool _isSending = false;
  String? _replyingTo; 

  String getChatRoomId(String a, String b) => (a.compareTo(b) > 0) ? "${b}_$a" : "${a}_$b";

  void sendMessage() async {
    if (_msgController.text.trim().isEmpty || currentUser == null) return;
    setState(() => _isSending = true);
    String text = _msgController.text.trim();
    String? repliedText = _replyingTo;
    _msgController.clear(); 
    setState(() => _replyingTo = null); 

    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    
    var msgData = {
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'text': text,
      'replyTo': repliedText ?? '',
      'reaction': '', // حقل الريأكت الجديد
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, 
    };

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add(msgData);
    setState(() => _isSending = false);
  }

  // دالة عرض شريط الريأكتات
  void _showReactionDialog(String docId, String chatRoomId) {
    List<String> emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((e) => GestureDetector(
            onTap: () {
              FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').doc(docId).update({'reaction': e});
              Navigator.pop(context);
            },
            child: Text(e, style: const TextStyle(fontSize: 28)),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold();
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF1A1A2E), title: Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 18))),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));

                // تحديث التخزين المحلي
                List<Map<dynamic, dynamic>> offlineMessages = [];
                if (snapshot.data!.docs.isNotEmpty) {
                  List<Map<String, dynamic>> toSave = snapshot.data!.docs.map((e) {
                    var data = e.data() as Map<String, dynamic>;
                    data['docId'] = e.id; // نحفظ الـ ID عشان الريأكتات
                    return data;
                  }).toList();
                  localChatsBox.put(chatRoomId, toSave);
                  offlineMessages = toSave;
                } else {
                  offlineMessages = List<Map<dynamic, dynamic>>.from(localChatsBox.get(chatRoomId, defaultValue: []));
                }

                return ListView.builder(
                  reverse: true, 
                  itemCount: offlineMessages.length,
                  itemBuilder: (context, index) {
                    var msg = offlineMessages[index];
                    bool isMe = msg['senderId'] == currentUser!.uid; 
                    bool isRead = msg['isRead'] == true;
                    String text = msg['text']?.toString() ?? '';
                    String replyTo = msg['replyTo']?.toString() ?? '';
                    String reaction = msg['reaction']?.toString() ?? '';
                    String docId = msg['docId']?.toString() ?? '';

                    return SwipeTo(
                      onRightSwipe: (details) => setState(() => _replyingTo = text),
                      child: GestureDetector(
                        onLongPress: () => _showReactionDialog(docId, chatRoomId), // تشغيل الريأكت
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF2A2A3E), 
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15), topRight: const Radius.circular(15),
                                    bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                                    bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                                  )
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (replyTo.isNotEmpty) 
                                      Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.only(bottom: 5), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text('رد على: $replyTo', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                    Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                    if (isMe) Padding(padding: const EdgeInsets.only(top: 4.0), child: Icon(Icons.done_all, size: 14, color: isRead ? Colors.blueAccent : Colors.white54))
                                  ],
                                ),
                              ),
                              // رسم الريأكت فوق الرسالة لو موجود
                              if (reaction.isNotEmpty)
                                Positioned(
                                  bottom: -5, right: isMe ? 20 : null, left: isMe ? null : 20,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purpleAccent, width: 1)),
                                    child: Text(reaction, style: const TextStyle(fontSize: 14)),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          if (_replyingTo != null)
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFF1A1A2E), child: Row(children: [Expanded(child: Text('الرد على: $_replyingTo', style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _replyingTo = null))])),

          Container(
            padding: const EdgeInsets.all(8.0), color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgController, textDirection: TextDirection.rtl, decoration: InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFF2A2A3E), contentPadding: const EdgeInsets.symmetric(horizontal: 16)))),
                IconButton(icon: const Icon(Icons.send, color: Colors.purpleAccent, size: 28), onPressed: sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
