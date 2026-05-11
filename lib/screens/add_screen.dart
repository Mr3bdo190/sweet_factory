import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void uploadPost() async {
    if (_postController.text.trim().isEmpty && _image == null) return;
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? imageUrl;

      // لو اخترت صورة، ارفعها للكلاوديناري الأول
      if (_image != null) {
        imageUrl = await CloudinaryService().uploadImage(_image!);
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String username = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'username': username,
        'text': _postController.text.trim(),
        'imageUrl': imageUrl ?? '', 
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'savedBy': [],
      });

      if (mounted) {
        _postController.clear();
        setState(() => _image = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النشر بنجاح! 🚀', textDirection: TextDirection.rtl)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة بوست', style: TextStyle(color: Colors.purpleAccent)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'بتفكر في إيه؟ ...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18),
            ),
            if (_image != null) 
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 250,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.photo_library, color: Colors.purpleAccent, size: 30), onPressed: pickImage),
                const Text('إرفاق صورة', style: TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : uploadPost,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('نشر', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
