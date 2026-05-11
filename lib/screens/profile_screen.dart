import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart'; // استدعاء شاشة التعديل

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () async => await AuthService().logOut())
        ],
      ),
      body: user == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : Column(
              children: [
                const SizedBox(height: 10),
                const CircleAvatar(radius: 45, backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, size: 45, color: Colors.white)),
                const SizedBox(height: 10),
                StreamBuilder<DocumentSnapshot>( // خليناها Stream عشان تتحدث فوراً بعد التعديل
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var userData = snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox();
                    return Column(
                      children: [
                        Text(userData['name'] ?? 'مستخدم', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(userData['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        if (userData['bio'] != null && userData['bio'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(userData['bio'], style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center, textDirection: TextDirection.rtl),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                          },
                          icon: const Icon(Icons.edit, size: 18, color: Colors.purpleAccent),
                          label: const Text('تعديل الحساب', style: TextStyle(color: Colors.purpleAccent)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purpleAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('بوستاتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: user.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لسه معملتش أي بوستات.', style: TextStyle(color: Colors.grey)));

                      var docs = snapshot.data!.docs;
                      docs.sort((a, b) {
                        Timestamp? t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        Timestamp? t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        if (t1 == null || t2 == null) return 0;
                        return t2.compareTo(t1);
                      });

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var postDoc = docs[index];
                          var post = postDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: const Color(0xFF1A1A2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(Icons.article_outlined, color: Colors.grey),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () async => await FirebaseFirestore.instance.collection('posts').doc(postDoc.id).delete(),
                                      )
                                    ],
                                  ),
                                  Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.white), textDirection: TextDirection.rtl),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
