import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const RegisterScreen({super.key, required this.showLoginScreen});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future signUp() async {
    if (_phoneController.text.trim().isEmpty || _passwordController.text.trim().isEmpty || _nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // الخدعة: تحويل الرقم لإيميل وهمي للفايربيز
      String fakeEmail = "${_phoneController.text.trim()}@wateny.com";

      UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: _passwordController.text.trim(),
      );

      // حفظ بيانات المستخدم برقم الموبايل
      await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(), // ده اللي هنبحث بيه بعدين
        'email': fakeEmail,
        'bio': '',
        'profilePic': '',
        'followers': [],
        'following': [],
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_rounded, size: 100, color: Colors.purpleAccent),
              const SizedBox(height: 20),
              const Text('إنشاء حساب جديد', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(hintText: 'الاسم', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(hintText: 'رقم الموبايل (مثال: 010123...)', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(hintText: 'كلمة السر', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _isLoading ? null : signUp,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: widget.showLoginScreen,
                child: const Text('عندك حساب؟ سجل دخول', style: TextStyle(color: Colors.purpleAccent)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
