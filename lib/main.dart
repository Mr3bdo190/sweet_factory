import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/auth_toggle.dart';
import 'screens/main_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل قاعدة البيانات المحلية (Hive)
  await Hive.initFlutter();
  await Hive.openBox('local_chats'); // صندوق تخزين الرسائل
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(home: Scaffold(backgroundColor: Colors.black, body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(details.exceptionAsString(), style: const TextStyle(color: Colors.redAccent))))));
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
      home: FutureBuilder(
        future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: Color(0xFF0F0F1A), body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)));
                return authSnapshot.hasData ? const MainScreen() : const AuthToggle();
              },
            );
          }
          return const Scaffold(backgroundColor: Color(0xFF0F0F1A), body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)));
        },
      ),
    );
  }
}
