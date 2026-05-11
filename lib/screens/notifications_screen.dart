import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
              // بنجيب الإشعارات من قاعدة البيانات الخاصة بالمستخدم ده بس
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('مفيش إشعارات جديدة 🔔', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var notification = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.purpleAccent),
                        title: Text(notification['title'] ?? 'إشعار جديد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                        subtitle: Text(notification['body'] ?? '', style: const TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
