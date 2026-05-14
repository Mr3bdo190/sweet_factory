import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'admin_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1A1A2E), elevation: 0),
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            String? profilePic = userData['profilePic'];
            bool isAdmin = userData['isAdmin'] == true; // فحص الصلاحية من الفايربيز

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      // شيلنا الـ GestureDetector السري من هنا
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFF2A2A3E),
                        backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                        child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())), child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 20))))
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoTile(Icons.person, 'الاسم', userData['name'] ?? 'مستخدم', 'هذا ليس اسم المستخدم الخاص بك.'),
                const Divider(color: Colors.white24),
                _buildInfoTile(Icons.phone, 'الهاتف', userData['phone'] ?? 'لا يوجد رقم', ''),
                const Divider(color: Colors.white24),
                
                // زرار الإدارة بيظهر فقط لو أنت آدمن في الفايربيز
                if (isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 30),
                    title: const Text('لوحة تحكم الإدارة', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard())),
                  ),
                  
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
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
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, String subtitle) {
    return ListTile(leading: Icon(icon, color: Colors.grey, size: 30), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]));
  }
}
