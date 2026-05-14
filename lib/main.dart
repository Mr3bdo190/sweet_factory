import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_toggle.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // صائدة الأخطاء السحرية: لو التطبيق كرش هيكتبلك السبب بدل الشاشة البيضا
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  };

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
          // تأمين شاشة التحميل بلون التطبيق مش أبيض
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F0F1A),
              body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F1A),
              body: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent))),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          } else {
            return const AuthToggle();
          }
        },
      ),
    );
  }
}
