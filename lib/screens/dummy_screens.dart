// إحنا هنعدل الملف ده عشان نفصل الـ HomeScreen الحقيقية
import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('البحث 🔍', style: TextStyle(fontSize: 24)));
}

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('إضافة بوست ➕', style: TextStyle(fontSize: 24)));
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('الإشعارات 🔔', style: TextStyle(fontSize: 24)));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('حسابي 👤', style: TextStyle(fontSize: 24)));
}
