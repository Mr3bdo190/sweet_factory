import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Please log in to see notifications', style: TextStyle(color: GlassTheme.textPrimary)));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: GlassTheme.textPrimary)),
                  TextButton.icon(
                    onPressed: () async {
                      final snapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('notifications').where('isRead', isEqualTo: false).get();
                      final batch = FirebaseFirestore.instance.batch();
                      for (var doc in snapshot.docs) {
                        batch.update(doc.reference, {'isRead': true});
                      }
                      await batch.commit();
                    }, 
                    icon: const Icon(Icons.done_all, color: GlassTheme.primaryAccent), 
                    label: const Text('Mark all read', style: TextStyle(color: GlassTheme.primaryAccent))
                  )
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No notifications yet', style: TextStyle(color: GlassTheme.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final notif = doc.data() as Map<String, dynamic>;
                      final isRead = notif['isRead'] ?? false;

                      return GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            doc.reference.update({'isRead': true});
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.transparent : GlassTheme.primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: GlassTheme.secondaryAccent,
                                  backgroundImage: notif['senderImage'] != null && notif['senderImage'].toString().isNotEmpty
                                      ? NetworkImage(notif['senderImage'])
                                      : null,
                                  child: (notif['senderImage'] == null || notif['senderImage'].toString().isEmpty)
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(text: '${notif['senderName']} ', style: const TextStyle(fontWeight: FontWeight.bold, color: GlassTheme.textPrimary)),
                                            TextSpan(text: notif['content'], style: const TextStyle(color: GlassTheme.textPrimary)),
                                          ]
                                        )
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['createdAt'] != null ? timeago.format((notif['createdAt'] as Timestamp).toDate()) : 'Now',
                                        style: TextStyle(color: isRead ? GlassTheme.textSecondary : GlassTheme.primaryAccent, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 10, height: 10,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: GlassTheme.primaryAccent),
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
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
