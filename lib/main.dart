import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WatenyApp());
}

class WatenyApp extends StatelessWidget {
  const WatenyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wateny New Era',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'تم الربط بنجاح.. بداية عهد جديد!',
            style: TextStyle(fontSize: 20, color: Colors.purpleAccent),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}
