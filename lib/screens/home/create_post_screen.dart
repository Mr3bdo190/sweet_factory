import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/wateny_toast.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedMedia;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  bool _isPosting = false;
  String _privacy = 'Public';

  // المتغير الجديد لميزة النشر المجهول
  bool _isAnonymous = false;

  Future<void> _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final XFile? file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _selectedMedia = File(file.path);
        _isVideo = isVideo;
      });
      if (isVideo) {
        _videoController = VideoPlayerController.file(_selectedMedia!)
          ..initialize().then((_) => setState(() {}));
      }
    }
  }

  List<String> _extractTags(String text, String symbol) {
    final regex = RegExp(r'(?<=\s|^)' + symbol + r'(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  Future<void> _post() async {
    if (_contentController.text.isEmpty && _selectedMedia == null) return;
    setState(() => _isPosting = true);

    String? mediaUrl;
    if (_selectedMedia != null) {
      if (_isVideo) {
        mediaUrl = await CloudinaryService().uploadVideo(_selectedMedia!);
      } else {
        mediaUrl = await CloudinaryService().uploadImage(_selectedMedia!);
      }
      if (mediaUrl == null) {
        setState(() => _isPosting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Failed to upload media. Check internet connection or Cloudinary config.'),
              backgroundColor: Colors.redAccent));
        }
        return;
      }
    }

    final hashtags = _extractTags(_contentController.text, '#');
    final mentions = _extractTags(_contentController.text, '@');
    final user = FirebaseAuth.instance.currentUser;

    // Logic النشر المجهول
    final String authorNameToSave =
        _isAnonymous ? 'Anonymous User' : (user?.displayName ?? 'User');
    final String authorImageToSave = _isAnonymous ? '' : (user?.photoURL ?? '');

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user?.uid, // بنحتفظ بالـ ID عشان يقدر يمسح البوست بتاعه بعدين
      'authorName': authorNameToSave,
      'authorImage': authorImageToSave,
      'isAnonymous': _isAnonymous, // علامة مميزة في الداتا بيز
      'content': _contentController.text,
      'mediaUrl': mediaUrl,
      'postType':
          _isVideo ? 'video' : (_selectedMedia != null ? 'image' : 'text'),
      'hashtags': hashtags,
      'mentions': mentions,
      'privacy': _privacy,
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      WatenyToast.show(context, 'Success', 'Your post has been published!',
          icon: Icons.check_circle);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _post,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: GlassTheme.primaryAccent))
                : const Text('POST',
                    style: TextStyle(
                        color: GlassTheme.primaryAccent,
                        fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: _isAnonymous
                        ? Colors.grey[800]
                        : GlassTheme.secondaryAccent,
                    child: Icon(
                        _isAnonymous
                            ? Icons.visibility_off_outlined
                            : Icons.person,
                        color: Colors.white)),
                const SizedBox(width: 12),
                Text(
                    _isAnonymous
                        ? 'Posting Anonymously 🤫'
                        : 'What\'s on your mind?',
                    style: const TextStyle(
                        color: GlassTheme.textPrimary, fontSize: 16)),
                const Spacer(),
                DropdownButton<String>(
                  value: _privacy,
                  dropdownColor: GlassTheme.backgroundDark,
                  style: const TextStyle(
                      color: GlassTheme.primaryAccent,
                      fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: GlassTheme.primaryAccent),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => _privacy = newValue);
                  },
                  items: <String>['Public', 'Friends', 'Only Me']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == 'Public'
                                ? Icons.public
                                : (value == 'Friends'
                                    ? Icons.group
                                    : Icons.lock),
                            size: 16,
                            color: GlassTheme.primaryAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // زر النشر المجهول
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SwitchListTile(
                title: const Text('Anonymous Post',
                    style: TextStyle(
                        color: GlassTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                subtitle: const Text('Hide your name and profile picture',
                    style: TextStyle(
                        color: GlassTheme.textSecondary, fontSize: 12)),
                value: _isAnonymous,
                activeThumbColor: GlassTheme.primaryAccent,
                secondary: const Icon(Icons.privacy_tip_outlined,
                    color: GlassTheme.accentPink),
                onChanged: (bool value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            GlassContainer(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                style: const TextStyle(color: GlassTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText:
                      'Type here... Use # for hashtags and @ for mentions',
                  hintStyle: TextStyle(color: GlassTheme.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedMedia != null) ...[
              if (_isVideo &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 50,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      )
                    ],
                  ),
                )
              else if (!_isVideo)
                Image.file(_selectedMedia!, height: 200, fit: BoxFit.cover),
              TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Remove Media',
                    style: TextStyle(color: Colors.red)),
                onPressed: () => setState(() {
                  _selectedMedia = null;
                  _videoController?.dispose();
                  _videoController = null;
                }),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(isVideo: false),
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text('Photo',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          GlassTheme.glassWhite.withValues(alpha: 0.2)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(isVideo: true),
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text('Video',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          GlassTheme.glassWhite.withValues(alpha: 0.2)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
