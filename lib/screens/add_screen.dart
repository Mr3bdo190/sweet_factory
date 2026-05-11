import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  void uploadPost() async {
    if (_postController.text.trim().isEmpty) return; // لو البوست فاضي ميعملش حاجة

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // هنجيب اسم المستخدم من الداتا بيز عشان نحطه مع البوست
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String username = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';

        // رفع البوست لمجموعة posts في الفايربيز
        await FirebaseFirestore.instance.collection('posts').add({
          'uid': user.uid,
          'username': username,
          'text': _postController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(), // وقت السيرفر بالظبط
          'likes': [], // مصفوفة فاضية هنحط فيها اللايكات بعدين
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النشر بنجاح! 🚀', textDirection: TextDirection.rtl)));
          _postController.clear();
          // بعدين ممكن نخليه يرجعك للشاشة الرئيسية أوتوماتيك
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة بوست', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _postController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'بتفكر في إيه؟ ...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 20),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : uploadPost,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('نشر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
