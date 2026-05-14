import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../services/presence_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Box localChatsBox = Hive.box('local_chats');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    PresenceService().init();
    _restoreChatsFromCloud(); // تشغيل الاسترجاع التلقائي
  }

  // دالة الاسترجاع العبقرية
  Future<void> _restoreChatsFromCloud() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // لو التخزين المحلي فاضي (يعني التطبيق لسه متسطب)
    if (localChatsBox.isEmpty) {
      var chatsSnap = await FirebaseFirestore.instance.collection('chats').get();
      for (var chat in chatsSnap.docs) {
        if (chat.id.contains(user.uid)) {
          var msgsSnap = await chat.reference.collection('messages').orderBy('timestamp', descending: true).get();
          List<Map<String, dynamic>> toSave = msgsSnap.docs.map((e) {
            var data = e.data() as Map<String, dynamic>;
            data['docId'] = e.id;
            return data;
          }).toList();
          localChatsBox.put(chat.id, toSave);
        }
      }
    }
  }

  void _showSearchDialog(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('بحث برقم الهاتف', style: TextStyle(color: Colors.white)),
        content: TextField(controller: searchController, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: '010...', hintStyle: TextStyle(color: Colors.grey))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () async {
              String phone = searchController.text.trim();
              var res = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).get();
              if (res.docs.isNotEmpty) {
                var userData = res.docs.first.data();
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: userData['uid'], receiverName: userData['name'])));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرقم غير مسجل في وطني')));
              }
            },
            child: const Text('بدء دردشة'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wateny', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.grey), onPressed: () => _showSearchDialog(context)),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
        ],
        bottom: TabBar(controller: _tabController, indicatorColor: Colors.purpleAccent, tabs: const [Tab(text: 'الدردشات'), Tab(text: 'الحالات')]),
      ),
      body: TabBarView(controller: _tabController, children: const [ChatListScreen(), HomeScreen()]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.purpleAccent, onPressed: () => _showSearchDialog(context), child: const Icon(Icons.message, color: Colors.white)),
    );
  }
}
