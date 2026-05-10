import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // محاولة تشغيل الفايربيز
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const WatenyApp());
  } catch (e) {
    // لو ضرب إيرور، بدل ما يقفل هيعرضلك الشاشة دي
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Crash Info:\n$e',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    ));
  }
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
