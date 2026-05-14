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
    String? imageUrl = await CloudinaryService().uploadImage(File(pickedFile.path));
    if (imageUrl != null) {
      User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('stories').add({
        'uid': user!.uid,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
                leading: Stack(children: [const CircleAvatar(radius: 25, backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, color: Colors.white)), Positioned(bottom: 0, right: 0, child: Container(decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20)))]),
                title: const Text('حالتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(_isUploading ? 'جاري الرفع...' : 'إضافة تحديث لحالتي', style: const TextStyle(color: Colors.grey)),
                onTap: uploadStatus,
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('التحديثات الأخيرة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد حالات حالياً', style: TextStyle(color: Colors.grey))))
              else
                ...snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(data['uid']).get(),
                    builder: (context, userSnap) {
                      String name = userSnap.hasData ? (userSnap.data!.data() as Map<String, dynamic>)['name'] : 'تحميل...';
                      return ListTile(
                        leading: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.purpleAccent, width: 2)), child: CircleAvatar(backgroundImage: NetworkImage(data['imageUrl']))),
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        subtitle: const Text('منذ قليل'),
                        onTap: () => showDialog(context: context, builder: (_) => Scaffold(backgroundColor: Colors.black, body: Stack(children: [Center(child: Image.network(data['imageUrl'])), Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))]))),
                      );
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
