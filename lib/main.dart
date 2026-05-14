import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_toggle.dart';
import 'screens/main_screen.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      // هنا السحر: استخدمنا المفاتيح المزروعة
      home: FutureBuilder(
        future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
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

          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          );
        },
      ),
    );
  }
}
