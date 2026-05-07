import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/glass_theme.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    
    final url = await CloudinaryService().uploadImage(File(pickedFile.path), folder: 'stories');
    if (url != null) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('stories').add({
        'authorId': user?.uid,
        'authorName': user?.displayName ?? 'User',
        'authorImage': user?.photoURL ?? '',
        'mediaUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload story')));
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(title: const Text('Add Story')),
      body: Center(
        child: _isUploading 
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _uploadStory, 
                icon: const Icon(Icons.add_photo_alternate), 
                label: const Text('Select Image for Story')
              ),
      ),
    );
  }
}
