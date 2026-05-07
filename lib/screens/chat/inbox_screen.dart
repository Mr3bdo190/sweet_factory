import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
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
                  const Text('Messages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: GlassTheme.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: GlassTheme.textPrimary),
                    onPressed: () {
                      // Logic to start a new chat could go here
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: currentUserId == null 
                ? const Center(child: Text('Please login to view chats'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('chats')
                        .where('participants', arrayContains: currentUserId)
                        .orderBy('lastMessageTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No active chats', style: TextStyle(color: GlassTheme.textSecondary)));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final chatDoc = snapshot.data!.docs[index];
                          final chatData = chatDoc.data() as Map<String, dynamic>;
                          final isLocked = chatData['isLocked'] ?? false;
                          
                          final participants = List<String>.from(chatData['participants'] ?? []);
                          final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => 'Unknown');

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                            builder: (context, userSnap) {
                              String otherUserName = 'User: $otherUserId';
                              String? otherUserImage;
                              if (userSnap.hasData && userSnap.data!.exists) {
                                final uData = userSnap.data!.data() as Map<String, dynamic>;
                                otherUserName = uData['name'] ?? otherUserName;
                                otherUserImage = uData['profileImageUrl'];
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ChatScreen(chatId: chatDoc.id, otherUserId: otherUserName, isLocked: isLocked, passwordHash: chatData['password']),
                                    ));
                                  },
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: GlassTheme.secondaryAccent,
                                          backgroundImage: otherUserImage != null && otherUserImage.isNotEmpty ? NetworkImage(otherUserImage) : null,
                                          child: (otherUserImage == null || otherUserImage.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(otherUserName, style: const TextStyle(color: GlassTheme.textPrimary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (isLocked) const Icon(Icons.lock, color: GlassTheme.textSecondary, size: 16),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      isLocked ? 'Locked Chat' : (chatData['lastMessage'] ?? 'New chat'),
                                                      style: const TextStyle(color: GlassTheme.textSecondary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
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
                            }
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
