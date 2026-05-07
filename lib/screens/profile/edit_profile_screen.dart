import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/wateny_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  File? _profileImage;
  File? _coverImage;
  String? _existingProfileUrl;
  String? _existingCoverUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _bioController.text = data['bio'] ?? '';
        _nameController.text = data['name'] ?? user.displayName ?? '';
        setState(() {
          _existingProfileUrl = data['profileImageUrl'];
          _existingCoverUrl = data['coverImageUrl'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isCover) {
          _coverImage = File(pickedFile.path);
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? newProfileUrl = _existingProfileUrl;
    String? newCoverUrl = _existingCoverUrl;

    if (_profileImage != null) {
      newProfileUrl = await CloudinaryService().uploadImage(_profileImage!, folder: 'profiles');
    }
    if (_coverImage != null) {
      newCoverUrl = await CloudinaryService().uploadImage(_coverImage!, folder: 'covers');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      if (newProfileUrl != null) 'profileImageUrl': newProfileUrl,
      if (newCoverUrl != null) 'coverImageUrl': newCoverUrl,
    });

    if (mounted) {
      Navigator.pop(context);
      WatenyToast.show(context, 'Profile Updated', 'Your profile has been saved successfully.', icon: Icons.check_circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: GlassTheme.backgroundDark, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: CircularProgressIndicator(color: GlassTheme.primaryAccent)))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover Image
            GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                height: 200,
                width: double.infinity,
                color: GlassTheme.secondaryAccent,
                child: _coverImage != null 
                    ? Image.file(_coverImage!, fit: BoxFit.cover)
                    : (_existingCoverUrl != null 
                        ? Image.network(_existingCoverUrl!, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.add_a_photo, color: Colors.white, size: 40))),
              ),
            ),
            // Profile Image
            Transform.translate(
              offset: const Offset(0, -50),
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: GlassTheme.backgroundDark, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: GlassTheme.primaryAccent,
                    backgroundImage: _profileImage != null 
                        ? FileImage(_profileImage!) 
                        : (_existingProfileUrl != null ? NetworkImage(_existingProfileUrl!) as ImageProvider : null),
                    child: (_profileImage == null && _existingProfileUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: GlassTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: GlassTheme.textSecondary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: GlassTheme.glassBorder)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: GlassTheme.primaryAccent)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      style: const TextStyle(color: GlassTheme.textPrimary),
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        labelStyle: TextStyle(color: GlassTheme.textSecondary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: GlassTheme.glassBorder)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: GlassTheme.primaryAccent)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
