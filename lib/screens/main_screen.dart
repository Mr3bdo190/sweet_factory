import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart'; // هنخليها للـ Stories (الحالات)
import 'profile_screen.dart';
import '../services/presence_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    PresenceService().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wateny', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.grey), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'الدردشات'),
            Tab(text: 'الحالات'),
            Tab(text: 'المكالمات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatListScreen(), // شاشة الشاتات
          HomeScreen(),     // شاشة الحالات
          Center(child: Text('سجل المكالمات فارغ', style: TextStyle(color: Colors.grey))), 
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () {
          // زرار بدء شات جديد مع جهات الاتصال
        },
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
