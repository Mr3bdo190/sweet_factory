import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/contact_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    var synced = await ContactService.syncContacts();
    setState(() {
      _contacts = synced;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));

    return Scaffold(
      body: _contacts.isEmpty 
        ? const Center(child: Text('لا يوجد جهات اتصال مسجلة في التطبيق', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              var user = _contacts[index];
              if (user['uid'] == currentUser?.uid) return const SizedBox.shrink();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  backgroundImage: (user['profilePic'] != null && user['profilePic'] != '') ? NetworkImage(user['profilePic']) : null,
                  child: (user['profilePic'] == null || user['profilePic'] == '') ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(user['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(user['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: user['uid'], receiverName: user['name'])));
                },
              );
            },
          ),
    );
  }
}
