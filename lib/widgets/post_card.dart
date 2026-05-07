import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../theme/glass_theme.dart';
import 'glass_container.dart';
import 'comments_sheet.dart';
import 'full_screen_image_viewer.dart';
import '../screens/profile/profile_screen.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const PostCard({super.key, required this.post, required this.postId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  late bool _isLiked;
  late String? _myReaction;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    final likedBy = List<String>.from(widget.post['likedBy'] ?? []);
    final reactions = widget.post['reactions'] as Map<String, dynamic>? ?? {};
    
    _isLiked = likedBy.contains(currentUserId);
    _myReaction = reactions[currentUserId];
    _likesCount = widget.post['likesCount'] ?? 0;

    if (widget.post['postType'] == 'video' && widget.post['mediaUrl'] != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post['mediaUrl']))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike({String reaction = '👍'}) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    
    setState(() {
      if (_isLiked && _myReaction == reaction) {
        _isLiked = false;
        _myReaction = null;
        _likesCount--;
      } else {
        if (!_isLiked) _likesCount++;
        _isLiked = true;
        _myReaction = reaction;
      }
    });

    if (_isLiked) {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([currentUserId]),
        'likesCount': _likesCount,
        'reactions.$currentUserId': reaction,
      });
      // Send notification
      final authorId = widget.post['authorId'];
      if (authorId != null && authorId != currentUserId) {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('users').doc(authorId).collection('notifications').add({
          'type': 'like',
          'senderId': currentUserId,
          'senderName': user?.displayName ?? 'Someone',
          'senderImage': user?.photoURL ?? '',
          'content': 'liked your post.',
          'postId': widget.postId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([currentUserId]),
        'likesCount': _likesCount,
        'reactions.$currentUserId': FieldValue.delete(),
      });
    }
  }

  Future<void> _downloadMedia() async {
    if (widget.post['mediaUrl'] == null || 
        widget.post['mediaUrl'].toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No media to download')),
        );
      }
      return;
    }

    try {
      // Request storage permission if needed
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      // Get the download directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access downloads directory')),
          );
        }
        return;
      }
      final fileName = 'wateny_${DateTime.now().millisecondsSinceEpoch}';
      final String filePath;

      // Determine file extension based on post type
      if (widget.post['postType'] == 'video') {
        filePath = '${directory.path}/$fileName.mp4';
      } else {
        filePath = '${directory.path}/$fileName.jpg';
      }

      // Download the file
      final response = await http.get(Uri.parse(widget.post['mediaUrl']));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Media saved to Downloads')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download media')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading media: $e')),
        );
      }
    }
  }

  void _showReactionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReactionItem('👍'),
            _buildReactionItem('❤️'),
            _buildReactionItem('😂'),
            _buildReactionItem('😢'),
            _buildReactionItem('😡'),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionItem(String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _toggleLike(reaction: emoji);
      },
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }

  Widget _buildRichText(String text) {
    List<TextSpan> spans = [];
    final words = text.split(' ');
    
    for (var word in words) {
      if (word.startsWith('#')) {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)));
      } else if (word.startsWith('@')) {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: GlassTheme.textPrimary)));
      }
    }
    
    return RichText(text: TextSpan(children: spans));
  }

  String _getTimeAgo() {
    if (widget.post['createdAt'] == null) return 'Just now';
    final timestamp = widget.post['createdAt'] as Timestamp;
    return timeago.format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                final authorId = widget.post['authorId'];
                if (authorId != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: ProfileScreen(userId: authorId))));
                }
              },
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: GlassTheme.primaryAccent,
                        backgroundImage: widget.post['authorImage'] != null && widget.post['authorImage'].toString().isNotEmpty 
                            ? CachedNetworkImageProvider(widget.post['authorImage']) 
                            : null,
                        child: (widget.post['authorImage'] == null || widget.post['authorImage'].toString().isEmpty) 
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: GlassTheme.backgroundDark, width: 2),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post['authorName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, color: GlassTheme.textPrimary, fontSize: 16)),
                        Text(_getTimeAgo(), style: const TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                   IconButton(
                     icon: const Icon(Icons.bookmark_border, color: GlassTheme.textSecondary),
                     onPressed: () async {
                       final currentUid = FirebaseAuth.instance.currentUser?.uid;
                       if (currentUid != null) {
                         await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
                           'savedPosts': FieldValue.arrayUnion([widget.postId])
                         });
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post Saved!')));
                       }
                     },
                   ),
                   if (widget.post['mediaUrl'] != null && 
                       widget.post['mediaUrl'].toString().isNotEmpty &&
                       (widget.post['postType'] == 'image' || 
                        widget.post['postType'] == 'video'))
                     IconButton(
                       icon: const Icon(Icons.download, color: GlassTheme.textSecondary),
                       onPressed: () async {
                         await _downloadMedia();
                       },
                     ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.post['content'] != null && widget.post['content'].toString().isNotEmpty) ...[
              _buildRichText(widget.post['content']),
              const SizedBox(height: 12),
            ],
            if (widget.post['postType'] == 'video' && _videoController != null) ...[
              if (_videoController!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController!),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 50, color: Colors.white.withValues(alpha: 0.8),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPlaying ? _videoController!.pause() : _videoController!.play();
                              _isPlaying = !_isPlaying;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 12),
            ] else if (widget.post['mediaUrl'] != null && widget.post['mediaUrl'].toString().isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: widget.post['mediaUrl'])));
                },
                child: Hero(
                  tag: widget.post['mediaUrl'],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.post['mediaUrl'], 
                      fit: BoxFit.cover, 
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 200,
                        width: double.infinity,
                        color: GlassTheme.glassWhite,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        width: double.infinity,
                        color: GlassTheme.glassWhite,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.broken_image, color: GlassTheme.textSecondary, size: 50),
                            SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: GlassTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(),
                  onLongPress: _showReactionsMenu,
                  child: Row(
                    children: [
                      if (_isLiked && _myReaction != null && _myReaction != '👍')
                        Text(_myReaction!, style: const TextStyle(fontSize: 20))
                      else
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border, 
                          color: _isLiked ? Colors.redAccent : GlassTheme.textSecondary, 
                          size: 24
                        ),
                      const SizedBox(width: 4),
                      const Text('React', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 14)),
                    ],
                  )
                ),
                const SizedBox(width: 8),
                Text('$_likesCount', style: const TextStyle(color: GlassTheme.textSecondary, fontSize: 16)),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => CommentsSheet.show(context, widget.postId, widget.post['authorId']),
                  child: Row(
                    children: const [
                      Icon(Icons.comment_outlined, color: GlassTheme.textSecondary, size: 24),
                      SizedBox(width: 8),
                      Text('Comment', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
