import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().logOut();
              // مش محتاجين نعمل انتقال، الحارس الشخصي في main.dart هيطردك لصفحة الدخول لوحده!
            },
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                // سحب اسم المستخدم من الفايربيز
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(color: Colors.purpleAccent);
                    }
                    if (snapshot.hasData && snapshot.data!.exists) {
                      var userData = snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          Text(userData['name'] ?? 'مستخدم', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(userData['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      );
                    }
                    return const Text('البيانات غير متاحة');
                  },
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('بوستاتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                const SizedBox(height: 10),
                // سحب بوستات المستخدم ده بس
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: user.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لسه معملتش أي بوستات.', style: TextStyle(color: Colors.grey, fontSize: 18)));
                      }

                      // ترتيب البوستات في التطبيق عشان نتفادى إيرور الفايربيز
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
                          var post = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: const Color(0xFF1A1A2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                post['text'] ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                                textDirection: TextDirection.rtl,
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
