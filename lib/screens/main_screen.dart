import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../services/presence_service.dart';
import '../theme/apple_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Box localChatsBox = Hive.box('local_chats');
  final String currentAppVersion = "1.0.0"; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    PresenceService().init();
    _restoreChatsFromCloud();
    _checkForUpdates();
  }

  // .. (باقي دوال التحديث والاسترجاع زي ما هي)
  Future<void> _checkForUpdates() async { /* ... */ }
  Future<void> _restoreChatsFromCloud() async { /* ... */ }

  void _showSearchDialog(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppleDesign.surfaceTile1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('بحث برقم الهاتف', style: AppleDesign.tagline),
        content: TextField(controller: searchController, keyboardType: TextInputType.phone, style: AppleDesign.body, decoration: InputDecoration(hintText: '010...', hintStyle: AppleDesign.caption)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: AppleDesign.bodyMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppleDesign.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999))),
            onPressed: () async {
              String phone = searchController.text.trim();
              var res = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).get();
              if (res.docs.isNotEmpty) {
                var userData = res.docs.first.data();
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: userData['uid'], receiverName: userData['name'])));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرقم غير مسجل')));
              }
            },
            child: const Text('بدء دردشة', style: TextStyle(color: AppleDesign.onDark)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // عشان التابات تبان عايمة زي أبل
      backgroundColor: AppleDesign.surfaceBlack,
      appBar: AppBar(
        title: const Text('Wateny', style: TextStyle(color: AppleDesign.onDark, fontWeight: FontWeight.w600, fontSize: 21, letterSpacing: 0.231)),
        backgroundColor: AppleDesign.surfaceBlack,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppleDesign.primaryOnDark), onPressed: () => _showSearchDialog(context)),
          IconButton(icon: const Icon(Icons.person_outline, color: AppleDesign.primaryOnDark), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: TabBarView(controller: _tabController, children: const [ChatListScreen(), HomeScreen()]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppleDesign.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        onPressed: () => _showSearchDialog(context),
        child: const Icon(Icons.message, color: AppleDesign.onDark),
      ),
      // تصميم الزجاج المصنفر للتابات السفلية
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            color: AppleDesign.surfaceTile1.withOpacity(0.8),
            child: SafeArea(
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppleDesign.primary,
                labelColor: AppleDesign.primary,
                unselectedLabelColor: AppleDesign.bodyMuted,
                tabs: const [Tab(text: 'الدردشات', icon: Icon(Icons.chat_bubble_outline)), Tab(text: 'الحالات', icon: Icon(Icons.data_usage))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
