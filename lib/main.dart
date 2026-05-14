import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_toggle.dart';
import 'screens/main_screen.dart';

void main() async {
  // تأمين تشغيل الأدوات قبل أي حاجة
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Init Error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wateny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A2E), elevation: 0),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. حالة التحميل (عشان نمنع الشاشة السودا)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
            );
          }
          // 2. لو مسجل دخول
          if (snapshot.hasData) {
            return const MainScreen();
          } 
          // 3. لو مش مسجل
          else {
            return const AuthToggle();
          }
        },
      ),
    );
  }
}
