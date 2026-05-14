import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text('الرجاء تسجيل الدخول')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const Center(child: Text('خطأ في تحميل البيانات', style: TextStyle(color: Colors.white)));

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String? profilePic = userData['profilePic'];
          String name = userData['name'] ?? 'مستخدم';
          String phone = userData['phone'] ?? 'لا يوجد رقم';
          String bio = userData['bio'] ?? 'متوفر';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xFF2A2A3E),
                      backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                      child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoTile(Icons.person, 'الاسم', name, 'هذا ليس اسم المستخدم الخاص بك، بل الاسم الذي سيظهر لجهات اتصالك.'),
              const Divider(color: Colors.white24),
              _buildInfoTile(Icons.info_outline, 'الأخبار (Bio)', bio, ''),
              const Divider(color: Colors.white24),
              _buildInfoTile(Icons.phone, 'الهاتف', phone, ''),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 30),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: subtitle.isNotEmpty ? Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))) : null,
    );
  }
}
