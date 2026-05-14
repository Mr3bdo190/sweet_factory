import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isUploading = false;

  Future<void> uploadStatus() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    File imageFile = File(pickedFile.path);
    String? imageUrl = await CloudinaryService().uploadImage(imageFile);

    if (imageUrl != null) {
      User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('stories').add({
        'uid': user!.uid,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الحالة بنجاح! ✨')));
    }
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    const CircleAvatar(radius: 25, backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, color: Colors.white)),
                    Positioned(bottom: 0, right: 0, child: Container(decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20))),
                  ],
                ),
                title: const Text('حالتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(_isUploading ? 'جاري الرفع...' : 'انقر لإضافة حالة', style: const TextStyle(color: Colors.grey)),
                onTap: _isUploading ? null : uploadStatus,
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('التحديثات الأخيرة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                const Center(child: Text('لا توجد حالات حالياً', style: TextStyle(color: Colors.grey)))
              else
                ...snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.purpleAccent, width: 2)), child: CircleAvatar(backgroundImage: NetworkImage(data['imageUrl']))),
                    title: const Text('صديق', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('منذ قليل'),
                    onTap: () {
                      // عرض الحالة في شاشة كاملة
                      showDialog(context: context, builder: (_) => Scaffold(backgroundColor: Colors.black, body: Center(child: Image.network(data['imageUrl']))));
                    },
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
