import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart'; // استدعاء شاشة البروفايل الجديدة

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'ابحث عن أصدقاء...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('اكتب اسم للبحث 🔍', style: TextStyle(color: Colors.grey, fontSize: 18)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('مفيش حد بالاسم ده', style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, color: Colors.white)),
                      title: Text(user['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                      onTap: () {
                        // الانتقال لبروفايل الشخص ده عند الضغط عليه
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(
                          targetUserId: user['uid'],
                          targetUserName: user['name'] ?? 'مستخدم',
                        )));
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
