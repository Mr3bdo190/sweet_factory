import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/apple_theme.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  // 1. دالة قراءة الرسائل (أول ما تفتح الشات)
  void _markMessagesAsRead() async {
    if (currentUser == null) return;
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    var unreadMsgs = await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false).get();
        
    for (var doc in unreadMsgs.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  // 2. تحديث حالة "جاري الكتابة"
  void _updateTypingStatus(bool isTyping) {
    if (currentUser == null) return;
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'typing_${currentUser!.uid}': isTyping
    }, SetOptions(merge: true));
  }

  void sendMessage() async {
    if (_msgController.text.trim().isEmpty || currentUser == null) return;
    setState(() => _isSending = true);
    String text = _msgController.text.trim();
    String? repliedText = _replyingTo;
    _msgController.clear();
    setState(() => _replyingTo = null);
    _updateTypingStatus(false); // وقف "جاري الكتابة" بعد الإرسال

    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    var msgData = {
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'text': text,
      'replyTo': repliedText ?? '',
      'reaction': '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, 
    };

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add(msgData);
    setState(() => _isSending = false);
  }

  void _showReactionDialog(String docId, String chatRoomId) {
    List<String> emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppleDesign.surfaceTile2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  // تنسيق وقت "آخر ظهور"
  String _formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return "آخر ظهور: ${DateFormat('hh:mm a').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold();
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);

    return Scaffold(
      backgroundColor: AppleDesign.surfaceBlack,
      appBar: AppBar(
        backgroundColor: AppleDesign.surfaceTile1.withOpacity(0.9),
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppleDesign.primaryOnDark),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
          builder: (context, userSnap) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).snapshots(),
              builder: (context, chatSnap) {
                bool isOnline = false;
                String lastSeenTxt = '';
                bool isTyping = false;

                if (userSnap.hasData && userSnap.data!.data() != null) {
                  var data = userSnap.data!.data() as Map<String, dynamic>;
                  isOnline = data['isOnline'] ?? false;
                  lastSeenTxt = isOnline ? 'متصل الآن' : _formatLastSeen(data['lastSeen']);
                }
                if (chatSnap.hasData && chatSnap.data!.data() != null) {
                  var cData = chatSnap.data!.data() as Map<String, dynamic>;
                  isTyping = cData['typing_${widget.receiverId}'] ?? false;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiverName, style: AppleDesign.body.copyWith(fontWeight: FontWeight.w600)),
                    if (isTyping)
                      Text('جاري الكتابة...', style: AppleDesign.primaryOnDark.copyWith(fontSize: 12))
                    else if (lastSeenTxt.isNotEmpty)
                      Text(lastSeenTxt, style: AppleDesign.caption.copyWith(fontSize: 12)),
                  ],
                );
              }
            );
          }
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppleDesign.primary));

                  List<Map<dynamic, dynamic>> offlineMessages = [];
                  if (snapshot.data!.docs.isNotEmpty) {
                    List<Map<String, dynamic>> toSave = snapshot.data!.docs.map((e) {
                      var data = e.data() as Map<String, dynamic>;
                      data['docId'] = e.id;
                      return data;
                    }).toList();
                    localChatsBox.put(chatRoomId, toSave);
                    offlineMessages = toSave;
                    
                    // تحديث القراءة لو وأنت فاتح الشات جاتلك رسالة جديدة
                    _markMessagesAsRead();
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
                          onLongPress: () => _showReactionDialog(docId, chatRoomId),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppleDesign.primary : AppleDesign.surfaceTile2, 
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                                    )
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (replyTo.isNotEmpty) 
                                        Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.only(bottom: 5), decoration: BoxDecoration(color: AppleDesign.surfaceBlack.withOpacity(0.3), borderRadius: BorderRadius.circular(8)), child: Text('رد على: $replyTo', style: TextStyle(color: AppleDesign.onDark.withOpacity(0.7), fontSize: 12))),
                                      Text(text, style: AppleDesign.body.copyWith(color: AppleDesign.onDark)),
                                      if (isMe) Padding(padding: const EdgeInsets.only(top: 4.0), child: Icon(isRead ? Icons.done_all : Icons.check, size: 14, color: isRead ? Colors.lightBlueAccent : AppleDesign.bodyMuted))
                                    ],
                                  ),
                                ),
                                if (reaction.isNotEmpty)
                                  Positioned(
                                    bottom: -5, right: isMe ? 24 : null, left: isMe ? null : 24,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: AppleDesign.surfaceTile1, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppleDesign.hairline.withOpacity(0.2), width: 1)),
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
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: AppleDesign.surfaceTile1, child: Row(children: [Expanded(child: Text('الرد على: $_replyingTo', style: AppleDesign.caption, maxLines: 1, overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.close, color: AppleDesign.onDark), onPressed: () => setState(() => _replyingTo = null))])),

            Container(
              padding: const EdgeInsets.all(12.0),
              color: AppleDesign.surfaceBlack,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController, 
                      textDirection: TextDirection.rtl,
                      style: AppleDesign.body,
                      onChanged: (val) {
                        _updateTypingStatus(val.isNotEmpty);
                      },
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...', 
                        hintStyle: AppleDesign.caption,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9999), borderSide: BorderSide.none), 
                        filled: true, 
                        fillColor: AppleDesign.surfaceTile1, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      )
                    )
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppleDesign.primary,
                    child: IconButton(icon: const Icon(Icons.arrow_upward, color: AppleDesign.onDark), onPressed: sendMessage),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
