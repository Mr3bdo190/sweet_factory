import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future signIn() async {
    if (_phoneController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String fakeEmail = "${_phoneController.text.trim()}@wateny.com";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرقم أو كلمة السر غير صحيحة!', textDirection: TextDirection.rtl)));
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
              const Text('تسجيل الدخول', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(hintText: 'رقم الموبايل', filled: true, fillColor: const Color(0xFF1A1A2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
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
                  onPressed: _isLoading ? null : signIn,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: widget.showRegisterScreen,
                child: const Text('معندكش حساب؟ سجل دلوقتي', style: TextStyle(color: Colors.purpleAccent)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
