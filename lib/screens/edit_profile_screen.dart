import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  File? _image;
  String? _currentProfilePic;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    if (user == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    var data = doc.data() as Map<String, dynamic>;
    setState(() {
      _nameController.text = data['name'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _currentProfilePic = data['profilePic'];
    });
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void saveProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);

    String? imageUrl = _currentProfilePic;
    
    // رفع الصورة للكلاوديناري لو تم اختيار صورة جديدة
    if (_image != null) {
      String? uploadedUrl = await CloudinaryService().uploadImage(_image!);
      if (uploadedUrl != null) imageUrl = uploadedUrl;
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'profilePic': imageUrl ?? '',
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بروفايلك بشياكة! ✨', textDirection: TextDirection.rtl)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الحساب', style: TextStyle(color: Colors.purpleAccent)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF2A2A3E),
                    backgroundImage: _image != null 
                        ? FileImage(_image!) 
                        : (_currentProfilePic != null && _currentProfilePic!.isNotEmpty ? NetworkImage(_currentProfilePic!) : null) as ImageProvider?,
                    child: (_image == null && (_currentProfilePic == null || _currentProfilePic!.isEmpty)) 
                        ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F0F1A), width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(controller: _nameController, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: 'الاسم', filled: true, fillColor: const Color(0xFF2A2A3E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            TextField(controller: _bioController, textDirection: TextDirection.rtl, maxLines: 3, decoration: InputDecoration(labelText: 'نبذة عنك (Bio)', filled: true, fillColor: const Color(0xFF2A2A3E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _isLoading ? null : saveProfile, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ التعديلات', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}
