import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class CoupleGalleryScreen extends StatefulWidget {
  final String coupleId;

  const CoupleGalleryScreen({super.key, required this.coupleId});

  @override
  State<CoupleGalleryScreen> createState() => _CoupleGalleryScreenState();
}

class _CoupleGalleryScreenState extends State<CoupleGalleryScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final File imageFile = File(pickedFile.path);
      final url = await CloudinaryService().uploadImage(imageFile, folder: 'couple_gallery');
      if (url != null) {
        await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('gallery').add({
          'url': url,
          'uploaderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Our Gallery', style: TextStyle(color: Colors.pinkAccent)), backgroundColor: Colors.transparent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('gallery').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No photos yet', style: TextStyle(color: Colors.white)));

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(data['url'], fit: BoxFit.cover),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: _isUploading ? null : _uploadImage,
        child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}
