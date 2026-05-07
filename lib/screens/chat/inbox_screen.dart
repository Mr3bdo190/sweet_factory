import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../explore/explore_screen.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [GlassTheme.backgroundDark, GlassTheme.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Messages',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: GlassTheme.textPrimary)),
                  // تم تفعيل زرار إنشاء محادثة جديدة لفتح شاشة البحث
                  IconButton(
                    icon: const Icon(Icons.edit_square,
                        color: GlassTheme.textPrimary),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => Scaffold(
                                    appBar: AppBar(
                                        title: const Text('New Chat',
                                            style: TextStyle(
                                                color:
                                                    GlassTheme.textPrimary))),
                                    body: const ExploreScreen(),
                                  )));
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: currentUserId == null
                  ? const Center(child: Text('Please login to view chats'))
                  : StreamBuilder<QuerySnapshot>(
                      // تم إزالة orderBy من هنا لتجنب خطأ الـ Firestore Index
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants', arrayContains: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('No active chats',
                                  style: TextStyle(
                                      color: GlassTheme.textSecondary)));
                        }

                        // الترتيب المحلي للمحادثات حسب وقت آخر رسالة
                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = aData['lastMessageTime'] as Timestamp?;
                          final bTime = bData['lastMessageTime'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final chatDoc = docs[index];
                            final chatData =
                                chatDoc.data() as Map<String, dynamic>;
                            final isLocked = chatData['isLocked'] ?? false;
                            final participants = List<String>.from(
                                chatData['participants'] ?? []);
                            final otherUserId = participants.firstWhere(
                                (id) => id != currentUserId,
                                orElse: () => 'Unknown');

                            return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUserId)
                                    .get(),
                                builder: (context, userSnap) {
                                  String otherUserName = 'User';
                                  String? otherUserImage;
                                  bool isOnline =
                                      false; // المتغير الجديد عشان نقرأ حالة الاتصال

                                  if (userSnap.hasData &&
                                      userSnap.data!.exists) {
                                    final uData = userSnap.data!.data()
                                        as Map<String, dynamic>;
                                    otherUserName =
                                        uData['name'] ?? otherUserName;
                                    otherUserImage = uData['profileImageUrl'];
                                    isOnline = uData['isOnline'] ??
                                        false; // بنشوفه أونلاين ولا لأ
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                  chatId: chatDoc.id,
                                                  otherUserId: otherUserName,
                                                  isLocked: isLocked,
                                                  passwordHash:
                                                      chatData['password']),
                                            ));
                                      },
                                      child: GlassContainer(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // هنا الـ Stack اللي بيركب النقطة الخضراء فوق الصورة
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: GlassTheme
                                                      .secondaryAccent,
                                                  backgroundImage:
                                                      otherUserImage != null &&
                                                              otherUserImage
                                                                  .isNotEmpty
                                                          ? NetworkImage(
                                                              otherUserImage)
                                                          : null,
                                                  child: (otherUserImage ==
                                                              null ||
                                                          otherUserImage
                                                              .isEmpty)
                                                      ? const Icon(Icons.person,
                                                          color: Colors.white)
                                                      : null,
                                                ),
                                                if (isOnline) // لو أونلاين، النقطة تظهر
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Container(
                                                      width: 14,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.greenAccent,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: GlassTheme
                                                                .backgroundDark,
                                                            width: 2),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(otherUserName,
                                                      style: const TextStyle(
                                                          color: GlassTheme
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      if (isLocked)
                                                        const Icon(Icons.lock,
                                                            color: GlassTheme
                                                                .textSecondary,
                                                            size: 16),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          isLocked
                                                              ? 'Locked Chat'
                                                              : (chatData[
                                                                      'lastMessage'] ??
                                                                  'New chat'),
                                                          style: const TextStyle(
                                                              color: GlassTheme
                                                                  .textSecondary),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
