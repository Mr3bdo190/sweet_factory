import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_toggle.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // صائدة الأخطاء العظيمة بتاعتنا
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
      // هنا السحر: مش هنفتح التطبيق غير لما الفايربيز يحمل الأول
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // لو الفايربيز فيه مشكلة حقيقية، هيعرضها هنا بوضوح
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F1A),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Firebase Error:\n${snapshot.error}', style: const TextStyle(color: Colors.redAccent), textDirection: TextDirection.ltr),
                ),
              ),
            );
          }

          // لو الفايربيز حمل بنجاح، نبدأ نشوف تسجيل الدخول
          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(backgroundColor: Color(0xFF0F0F1A), body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)));
                }
                if (authSnapshot.hasData) {
                  return const MainScreen();
                } else {
                  return const AuthToggle();
                }
              },
            );
          }

          // شاشة تحميل شيك لحد ما الفايربيز يخلص
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          );
        },
      ),
    );
  }
}
