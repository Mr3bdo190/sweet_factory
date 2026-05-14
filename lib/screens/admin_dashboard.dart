import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة 🛡️', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.2),
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var user = snapshot.data!.docs[index];
              var data = user.data() as Map<String, dynamic>;
              bool isBanned = data['isBanned'] == true;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  backgroundImage: data['profilePic'] != null ? NetworkImage(data['profilePic']) : null,
                  child: data['profilePic'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(data['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['phone'] ?? 'بدون رقم', style: const TextStyle(color: Colors.grey)),
                trailing: Switch(
                  value: !isBanned, // لو مش محظور يبقى السويتش أخضر
                  activeColor: Colors.greenAccent,
                  inactiveThumbColor: Colors.redAccent,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('users').doc(user.id).update({'isBanned': !val});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
