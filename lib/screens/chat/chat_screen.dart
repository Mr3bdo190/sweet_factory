import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../services/cloudinary_service.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final bool isLocked;
  final String? passwordHash;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.isLocked = false,
    this.passwordHash,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  late final String currentUserId;
  bool _isUnlocked = false;
  bool _isUploading = false;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  Map<String, dynamic>? _replyToMsg;
  String? _editMsgId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _isUnlocked = !widget.isLocked;
    if (widget.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLockDialog());
    }

    // Typing indicator logic
    _msgController.addListener(() {
      final isTyping = _msgController.text.isNotEmpty;
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'typing.$currentUserId': isTyping,
      });
    });
  }

  @override
  void dispose() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'typing.$currentUserId': false,
    });
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _showLockDialog() {
    final TextEditingController passController = TextEditingController();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              backgroundColor: GlassTheme.backgroundDark,
              title: const Text('Locked Chat', style: TextStyle(color: GlassTheme.textPrimary)),
              content: GlassTextField(
                controller: passController,
                hintText: 'Enter Password',
                prefixIcon: Icons.lock,
                isPassword: true,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Back', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passController.text == widget.passwordHash) {
                      setState(() => _isUnlocked = true);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
                    }
                  },
                  child: const Text('Unlock'),
                )
              ],
            ));
  }

  Future<void> _sendMessage(String text, {String? mediaUrl, String type = 'text'}) async {
    if (text.isEmpty && mediaUrl == null) return;

    if (_editMsgId != null) {
      // Edit mode
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(_editMsgId).update({
        'content': text,
        'editedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _editMsgId = null;
        _msgController.clear();
      });
      return;
    }

    final data = {
      'senderId': currentUserId,
      'content': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent', // sent, delivered, read
    };

    if (_replyToMsg != null) {
      data['replyToId'] = _replyToMsg!['id'] ?? '';
      data['replyToText'] = _replyToMsg!['content'] ?? 'Attachment';
    }

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add(data);

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': type == 'text' ? text : 'Sent a $type',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
    setState(() => _replyToMsg = null);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final url = await CloudinaryService().uploadImage(File(pickedFile.path), folder: 'chat_images');
      if (url != null) await _sendMessage('', mediaUrl: url, type: 'image');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      final file = File(result.files.single.path!);
      final url = await CloudinaryService().uploadRawFile(file, folder: 'chat_files');
      if (url != null) await _sendMessage(result.files.single.name, mediaUrl: url, type: 'file');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _isUploading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }
      
       Position position = await Geolocator.getCurrentPosition(
         locationSettings: const LocationSettings(
           accuracy: LocationAccuracy.high,
         ),
       );
      await _sendMessage('${position.latitude},${position.longitude}', type: 'location');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing location: $e')));
    }
    setState(() => _isUploading = false);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() => _isUploading = true);
        final url = await CloudinaryService().uploadAudio(File(path), folder: 'chat_audio');
        if (url != null) await _sendMessage('', mediaUrl: url, type: 'audio');
        setState(() => _isUploading = false);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio permission required.')));
      }
    }
  }

  void _showMenu() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: GlassTheme.textPrimary),
                    title: const Text('View Profile', style: TextStyle(color: GlassTheme.textPrimary)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: GlassTheme.textPrimary),
                    title: const Text('Lock Chat', style: TextStyle(color: GlassTheme.textPrimary)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'isLocked': true, 'password': '1234'});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Chat', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).delete();
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ));
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _buildAttachmentIcon(Icons.image, Colors.purple, 'Gallery', () { Navigator.pop(context); _pickImage(); }),
            _buildAttachmentIcon(Icons.insert_drive_file, Colors.blue, 'Document', () { Navigator.pop(context); _pickFile(); }),
            _buildAttachmentIcon(Icons.location_on, Colors.green, 'Location', () { Navigator.pop(context); _shareLocation(); }),
          ],
        ),
      )
    );
  }

  Widget _buildAttachmentIcon(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 30, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: GlassTheme.backgroundDark,
        appBar: AppBar(title: const Text('Locked Chat')),
        body: const Center(child: Icon(Icons.lock, size: 50, color: GlassTheme.textSecondary)),
      );
    }

    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserId, style: const TextStyle(fontSize: 16)),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final typingMap = data['typing'] as Map<String, dynamic>? ?? {};
                bool isOtherTyping = false;
                typingMap.forEach((key, value) {
                  if (key != currentUserId && value == true) isOtherTyping = true;
                });
                if (isOtherTyping) return const Text('typing...', style: TextStyle(fontSize: 12, color: GlassTheme.primaryAccent, fontStyle: FontStyle.italic));
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _showMenu),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    msg['id'] = doc.id; // Inject ID for replies
                    
                    return MessageBubble(
                      msg: msg,
                      messageId: doc.id,
                      chatId: widget.chatId,
                      isMe: msg['senderId'] == currentUserId,
                      onReply: (m) => setState(() => _replyToMsg = m),
                      onEdit: (m, id) {
                        setState(() {
                          _editMsgId = id;
                          _msgController.text = m['content'] ?? '';
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(),
          if (_replyToMsg != null || _editMsgId != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: GlassTheme.glassWhite.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(_editMsgId != null ? Icons.edit : Icons.reply, color: GlassTheme.primaryAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editMsgId != null ? 'Editing message...' : 'Replying to: ${_replyToMsg!['content'] ?? 'Attachment'}',
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _replyToMsg = null;
                        _editMsgId = null;
                        _msgController.clear();
                      });
                    },
                  )
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: GlassTheme.glassWhite.withValues(alpha: 0.1),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.add, color: GlassTheme.textPrimary), onPressed: _showAttachmentMenu),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: GlassTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: GlassTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.redAccent : GlassTheme.textPrimary),
                    onPressed: _toggleRecording,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: GlassTheme.primaryAccent),
                    onPressed: () => _sendMessage(_msgController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
