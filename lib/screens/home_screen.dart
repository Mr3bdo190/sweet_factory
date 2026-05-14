import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
            title: const Text('حالتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('انقر لإضافة حالة', style: TextStyle(color: Colors.grey)),
            onTap: () {
              // سيتم برمجة رفع الحالة بالكلاوديناري هنا قريباً!
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('التحديثات الأخيرة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('لا توجد حالات حالياً', style: TextStyle(color: Colors.grey)),
            ),
          )
        ],
      ),
    );
  }
}
