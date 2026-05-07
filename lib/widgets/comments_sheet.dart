import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';
import '../screens/profile/profile_screen.dart';
import '../services/cloudinary_service.dart';
import '../widgets/wateny_toast.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String? postAuthorId;

  const CommentsSheet({super.key, required this.postId, this.postAuthorId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();

  static void show(BuildContext context, String postId, String? postAuthorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsSheet(postId: postId, postAuthorId: postAuthorId),
    );
  }
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Audio Variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isUploading = false;
  String? _currentlyPlayingId; // To track which voice note is playing

  @override
  void dispose() {
    _commentController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _postComment({String? audioUrl}) async {
    final text = _commentController.text.trim();
    if (text.isEmpty && audioUrl == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'authorId': user.uid,
      'authorName': user.displayName ?? 'User',
      'authorImage': user.photoURL ?? '',
      'content': audioUrl != null ? '🎤 Voice Comment' : text,
      'type': audioUrl != null ? 'audio' : 'text',
      'mediaUrl': audioUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'likedBy': [],
    });

    if (widget.postAuthorId != null && widget.postAuthorId != user.uid) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.postAuthorId)
          .collection('notifications')
          .add({
        'type': 'comment',
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Someone',
        'senderImage': user.photoURL ?? '',
        'content': audioUrl != null
            ? 'left a voice comment on your post.'
            : 'commented on your post: "$text"',
        'postId': widget.postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _commentController.clear();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop Recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        setState(() => _isUploading = true);
        final url = await CloudinaryService()
            .uploadAudio(File(path), folder: 'voice_comments');
        if (url != null) {
          await _postComment(audioUrl: url);
        } else {
          if (mounted)
            WatenyToast.show(
                context, 'Error', 'Failed to upload voice comment.',
                icon: Icons.error);
        }
        setState(() => _isUploading = false);
      }
    } else {
      // Start Recording
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/comment_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      } else {
        if (mounted)
          WatenyToast.show(
              context, 'Permission Denied', 'Microphone access is required.');
      }
    }
  }

  Future<void> _toggleCommentLike(
      String commentId, List<String> likedBy, int likesCount) async {
    final isLiked = likedBy.contains(currentUserId);
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    if (isLiked) {
      await commentRef.update({
        'likedBy': FieldValue.arrayRemove([currentUserId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await commentRef.update({
        'likedBy': FieldValue.arrayUnion([currentUserId]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: GlassTheme.backgroundDark.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: GlassTheme.glassBorder),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Comments',
              style: TextStyle(
                  color: GlassTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Divider(color: GlassTheme.glassBorder),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No comments yet.',
                          style: TextStyle(color: GlassTheme.textSecondary)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final commentDoc = snapshot.data!.docs[index];
                    final comment = commentDoc.data() as Map<String, dynamic>;
                    final likedBy = List<String>.from(comment['likedBy'] ?? []);
                    final isLiked = likedBy.contains(currentUserId);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final authorId = comment['authorId'];
                              if (authorId != null) {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                            body: ProfileScreen(
                                                userId: authorId))));
                              }
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: GlassTheme.primaryAccent,
                              backgroundImage: comment['authorImage'] != null &&
                                      comment['authorImage']
                                          .toString()
                                          .isNotEmpty
                                  ? NetworkImage(comment['authorImage'])
                                  : null,
                              child: (comment['authorImage'] == null ||
                                      comment['authorImage'].toString().isEmpty)
                                  ? const Icon(Icons.person,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final authorId = comment['authorId'];
                                      if (authorId != null) {
                                        Navigator.pop(context);
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => Scaffold(
                                                    body: ProfileScreen(
                                                        userId: authorId))));
                                      }
                                    },
                                    child: Text(comment['authorName'] ?? 'User',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: GlassTheme.textPrimary)),
                                  ),
                                  const SizedBox(height: 8),

                                  // Voice Player OR Text
                                  if (comment['type'] == 'audio' &&
                                      comment['mediaUrl'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: GlassTheme.primaryAccent
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: GlassTheme.primaryAccent
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _currentlyPlayingId ==
                                                      commentDoc.id
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_fill,
                                              color: GlassTheme.primaryAccent,
                                              size: 28,
                                            ),
                                            onPressed: () async {
                                              if (_currentlyPlayingId ==
                                                  commentDoc.id) {
                                                await _audioPlayer.pause();
                                                setState(() =>
                                                    _currentlyPlayingId = null);
                                              } else {
                                                await _audioPlayer.play(
                                                    UrlSource(
                                                        comment['mediaUrl']));
                                                setState(() =>
                                                    _currentlyPlayingId =
                                                        commentDoc.id);
                                                _audioPlayer.onPlayerComplete
                                                    .listen((_) {
                                                  if (mounted)
                                                    setState(() =>
                                                        _currentlyPlayingId =
                                                            null);
                                                });
                                              }
                                            },
                                          ),
                                          const Text('Voice Note',
                                              style: TextStyle(
                                                  color: GlassTheme.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(comment['content'] ?? '',
                                        style: const TextStyle(
                                            color: GlassTheme.textPrimary)),

                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        comment['createdAt'] != null
                                            ? timeago.format(
                                                (comment['createdAt']
                                                        as Timestamp)
                                                    .toDate())
                                            : 'Now',
                                        style: const TextStyle(
                                            color: GlassTheme.textSecondary,
                                            fontSize: 10),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _toggleCommentLike(
                                            commentDoc.id,
                                            likedBy,
                                            comment['likesCount'] ?? 0),
                                        child: Text(
                                          'Like',
                                          style: TextStyle(
                                            color: isLiked
                                                ? GlassTheme.primaryAccent
                                                : GlassTheme.textSecondary,
                                            fontWeight: isLiked
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if ((comment['likesCount'] ?? 0) > 0) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.favorite,
                                            size: 12,
                                            color: GlassTheme.primaryAccent),
                                        const SizedBox(width: 2),
                                        Text('${comment['likesCount']}',
                                            style: const TextStyle(
                                                color: GlassTheme.textSecondary,
                                                fontSize: 10)),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: GlassTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'Recording voice note...'
                          : 'Write a comment...',
                      hintStyle: TextStyle(
                          color: _isRecording
                              ? Colors.redAccent
                              : GlassTheme.textSecondary),
                      filled: true,
                      fillColor: GlassTheme.glassWhite.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    readOnly: _isRecording, // تعطيل الكتابة وقت التسجيل
                  ),
                ),
                const SizedBox(width: 8),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: GlassTheme.primaryAccent, strokeWidth: 2)),
                  )
                else ...[
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording
                            ? Colors.redAccent
                            : GlassTheme.textSecondary),
                    onPressed: _toggleRecording,
                  ),
                  if (!_isRecording)
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: GlassTheme.primaryAccent),
                      onPressed: () => _postComment(),
                    ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
