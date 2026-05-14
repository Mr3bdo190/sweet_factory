import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/cloudinary_service.dart';

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
  
  // التحديث الجديد للمكتبة هنا! (AudioRecorder بدل Record)
  final AudioRecorder _audioRecorder = AudioRecorder(); 
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isSending = false;
  bool _isRecording = false;
  File? _image;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String getChatRoomId(String a, String b) => (a.compareTo(b) > 0) ? "${b}_$a" : "${a}_$b";

  void _updateTypingStatus(bool isTyping) {
    if (currentUser == null) return;
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'typing_${currentUser!.uid}': isTyping
    }, SetOptions(merge: true));
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      sendMessage(); 
    }
  }

  // تحديث دالة التسجيل للطريقة الجديدة
  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isRecording = true);
      // بنحفظ الملف في مسار مؤقت عشان المكتبة الجديدة بتطلب مسار
      String tempPath = '${Directory.systemTemp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: tempPath);
    }
  }

  Future<void> stopRecordingAndSend() async {
    setState(() => _isRecording = false);
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() => _isSending = true);
      String? audioUrl = await CloudinaryService().uploadAudio(File(path));
      if (audioUrl != null) {
        String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
        await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
          'senderId': currentUser!.uid,
          'receiverId': widget.receiverId,
          'audioUrl': audioUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false, 
        });
      }
      setState(() => _isSending = false);
    }
  }

  void sendMessage() async {
    if ((_msgController.text.trim().isEmpty && _image == null) || currentUser == null) return;
    setState(() => _isSending = true);
    String text = _msgController.text.trim();
    _msgController.clear(); 
    _updateTypingStatus(false);

    String? imageUrl;
    if (_image != null) {
      imageUrl = await CloudinaryService().uploadImage(_image!);
      setState(() => _image = null);
    }

    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'text': text,
      'imageUrl': imageUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, 
    });
    setState(() => _isSending = false);
  }

  void markMessagesAsRead(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['receiverId'] == currentUser!.uid && data['isRead'] == false) {
        doc.reference.update({'isRead': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold();
    String chatRoomId = getChatRoomId(currentUser!.uid, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
          builder: (context, userSnapshot) {
            bool isOnline = false;
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              var uData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              isOnline = uData['isOnline'] == true;
            }
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).snapshots(),
              builder: (context, chatSnapshot) {
                bool isTyping = false;
                if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                   var cData = chatSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                   isTyping = cData['typing_${widget.receiverId}'] == true;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      isTyping ? 'جاري الكتابة...' : (isOnline ? 'متصل الآن' : ''),
                      style: TextStyle(color: isTyping ? Colors.purpleAccent : Colors.greenAccent, fontSize: 12),
                    )
                  ],
                );
              },
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                markMessagesAsRead(snapshot.data!.docs);

                return ListView.builder(
                  reverse: true, 
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var msg = snapshot.data!.docs[index].data() as Map<String, dynamic>? ?? {};
                    
                    String senderId = msg['senderId']?.toString() ?? '';
                    bool isMe = senderId == currentUser!.uid; 
                    bool isRead = msg['isRead'] == true;
                    String audioUrl = msg['audioUrl']?.toString() ?? '';
                    String imageUrl = msg['imageUrl']?.toString() ?? '';
                    String text = msg['text']?.toString() ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isMe ? Colors.purpleAccent : const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(bottom: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imageUrl, width: 200, fit: BoxFit.cover))),
                            if (audioUrl.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                                    onPressed: () => _audioPlayer.play(UrlSource(audioUrl)),
                                  ),
                                  const Text('صوتية 🎵', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            if (text.isNotEmpty) 
                              Text(text, style: const TextStyle(color: Colors.white, fontSize: 16), textDirection: TextDirection.rtl),
                            if (isMe) 
                              Padding(padding: const EdgeInsets.only(top: 4.0), child: Icon(Icons.done_all, size: 16, color: isRead ? Colors.blueAccent : Colors.white70))
                          ],
                        ),
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
                IconButton(icon: const Icon(Icons.image, color: Colors.purpleAccent, size: 28), onPressed: pickImage),
                GestureDetector(
                  onLongPress: startRecording, 
 // Added delete logic below
                  onLongPressUp: stopRecordingAndSend,
                  child: CircleAvatar(
                    backgroundColor: _isRecording ? Colors.redAccent : Colors.purpleAccent,
                    child: Icon(_isRecording ? Icons.mic_none : Icons.mic, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgController, 
                    textDirection: TextDirection.rtl,
                    onChanged: (val) => _updateTypingStatus(val.trim().isNotEmpty),
                    decoration: InputDecoration(hintText: _isRecording ? 'جاري التسجيل...' : 'اكتب رسالة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFF2A2A3E), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                  ),
                ),
                _isSending 
                  ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 2))) 
                  : IconButton(icon: const Icon(Icons.send, color: Colors.purpleAccent, size: 28), onPressed: sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
