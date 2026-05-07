import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/glass_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/post_card.dart';
import '../chat/chat_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../widgets/wateny_toast.dart';
import '../couple/couple_hub_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final targetUserId = userId ?? currentUserId;
    final isMe = targetUserId == currentUserId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: targetUserId == null
          ? const Center(
              child: Text('Not logged in',
                  style: TextStyle(color: GlassTheme.textPrimary)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetUserId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? 'Wateny User';
                final bio = userData['bio'] ?? 'Hello, I am using Wateny!';
                final profileImageUrl = userData['profileImageUrl'];
                final coverImageUrl = userData['coverImageUrl'];
                final friendsCount =
                    (userData['friends'] as List?)?.length ?? 0;
                final partnerId = userData['partnerId'];
                final partnerRequests =
                    List<String>.from(userData['partnerRequests'] ?? []);

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      backgroundColor: GlassTheme.backgroundDark,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Cover Image
                            coverImageUrl != null &&
                                    coverImageUrl.toString().isNotEmpty
                                ? Image.network(coverImageUrl,
                                    fit: BoxFit.cover)
                                : Container(color: GlassTheme.secondaryAccent),

                            // Dark overlay for text readability
                            Container(
                                color: Colors.black.withValues(alpha: 0.3)),

                            Positioned(
                              bottom: 20,
                              left: 20,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: GlassTheme.backgroundDark,
                                          width: 4),
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: GlassTheme.primaryAccent,
                                      backgroundImage:
                                          profileImageUrl != null &&
                                                  profileImageUrl
                                                      .toString()
                                                      .isNotEmpty
                                              ? NetworkImage(profileImageUrl)
                                              : null,
                                      child: (profileImageUrl == null ||
                                              profileImageUrl
                                                  .toString()
                                                  .isEmpty)
                                          ? const Icon(Icons.person,
                                              size: 50, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 5,
                                                  color: Colors.black)
                                            ]),
                                      ),
                                      Text(
                                        '$friendsCount Friends',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 5,
                                                  color: Colors.black)
                                            ]),
                                      ),
                                      if (partnerId != null)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: Colors.pinkAccent
                                                  .withValues(alpha: 0.8),
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.favorite,
                                                  size: 14,
                                                  color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('In a Relationship',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        if (isMe)
                          IconButton(
                            icon:
                                const Icon(Icons.settings, color: Colors.white),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen())),
                          ),
                        if (isMe)
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () => _logout(context),
                          )
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bio',
                                style: TextStyle(
                                    color: GlassTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(bio,
                                style: const TextStyle(
                                    color: GlassTheme.textSecondary,
                                    fontSize: 16)),
                            const SizedBox(height: 16),
                            if (isMe)
                              Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const EditProfileScreen()));
                                      },
                                      icon: const Icon(Icons.edit,
                                          color: GlassTheme.primaryAccent),
                                      label: const Text('Edit Profile',
                                          style: TextStyle(
                                              color: GlassTheme.primaryAccent)),
                                    ),
                                    if (partnerId != null)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      CoupleHubScreen(
                                                          partnerId: partnerId,
                                                          partnerName:
                                                              'Partner')));
                                        },
                                        icon: const Icon(Icons.favorite,
                                            color: Colors.white),
                                        label: const Text('Enter Love Hub',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent),
                                      ),
                                    if (partnerId == null &&
                                        partnerRequests.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final requesterId =
                                              partnerRequests.first;
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(currentUserId)
                                              .update({
                                            'partnerId': requesterId,
                                            'relationshipStartDate':
                                                FieldValue.serverTimestamp(),
                                            'partnerRequests':
                                                FieldValue.arrayRemove(
                                                    [requesterId]),
                                          });
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(requesterId)
                                              .update({
                                            'partnerId': currentUserId,
                                            'relationshipStartDate':
                                                FieldValue.serverTimestamp(),
                                          });
                                          if (context.mounted)
                                            WatenyToast.show(
                                                context,
                                                'Partnership Accepted',
                                                'You are now linked!');
                                        },
                                        icon: const Icon(Icons.favorite_border,
                                            color: Colors.white),
                                        label: const Text(
                                            'Accept Partner Request',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent),
                                      ),
                                  ])
                            else
                              Column(
                                children: [
                                  if (partnerId == currentUserId)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      CoupleHubScreen(
                                                          partnerId:
                                                              targetUserId,
                                                          partnerName: name)));
                                        },
                                        icon: const Icon(Icons.favorite,
                                            color: Colors.white),
                                        label: const Text('Enter Love Hub',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent),
                                      ),
                                    )
                                  else if (partnerId == null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (partnerRequests
                                              .contains(currentUserId)) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(targetUserId)
                                                .update({
                                              'partnerRequests':
                                                  FieldValue.arrayRemove(
                                                      [currentUserId])
                                            });
                                            if (context.mounted)
                                              WatenyToast.show(
                                                  context,
                                                  'Request Canceled',
                                                  'Partner request canceled.');
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(targetUserId)
                                                .update({
                                              'partnerRequests':
                                                  FieldValue.arrayUnion(
                                                      [currentUserId])
                                            });
                                            if (context.mounted)
                                              WatenyToast.show(
                                                  context,
                                                  'Request Sent',
                                                  'Partner request sent!',
                                                  icon: Icons.favorite);
                                          }
                                        },
                                        icon: Icon(
                                            partnerRequests
                                                    .contains(currentUserId)
                                                ? Icons.cancel
                                                : Icons.favorite_border,
                                            color: Colors.white),
                                        label: Text(
                                            partnerRequests
                                                    .contains(currentUserId)
                                                ? 'Cancel Partner Request'
                                                : 'Request Partnership 💍',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: partnerRequests
                                                    .contains(currentUserId)
                                                ? Colors.grey
                                                : Colors.pinkAccent),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final currentUid = FirebaseAuth
                                                .instance.currentUser!.uid;
                                            final targetDoc =
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(targetUserId)
                                                    .get();
                                            final targetFriends =
                                                List<String>.from(targetDoc
                                                        .data()?['friends'] ??
                                                    []);

                                            if (targetFriends
                                                .contains(currentUid)) {
                                              // Remove friend
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(targetUserId)
                                                  .update({
                                                'friends':
                                                    FieldValue.arrayRemove(
                                                        [currentUid])
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(currentUid)
                                                  .update({
                                                'friends':
                                                    FieldValue.arrayRemove(
                                                        [targetUserId])
                                              });
                                              if (context.mounted)
                                                WatenyToast.show(
                                                    context,
                                                    'Unfriended',
                                                    'You are no longer friends.');
                                            } else {
                                              // Add friend (Simplified: directly adds them for now)
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(targetUserId)
                                                  .update({
                                                'friends':
                                                    FieldValue.arrayUnion(
                                                        [currentUid])
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(currentUid)
                                                  .update({
                                                'friends':
                                                    FieldValue.arrayUnion(
                                                        [targetUserId])
                                              });
                                              if (context.mounted)
                                                WatenyToast.show(
                                                    context,
                                                    'Friend Added',
                                                    'You are now friends!',
                                                    icon: Icons.check_circle);
                                            }
                                          },
                                          icon: const Icon(Icons.person_add,
                                              color: Colors.white),
                                          label: const Text('Friend',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  GlassTheme.secondaryAccent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20))),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final currentUid = FirebaseAuth
                                                .instance.currentUser!.uid;
                                            final query =
                                                await FirebaseFirestore.instance
                                                    .collection('chats')
                                                    .where('participants',
                                                        arrayContains:
                                                            currentUid)
                                                    .get();

                                            String? chatId;
                                            for (var doc in query.docs) {
                                              final participants =
                                                  List<String>.from(
                                                      doc['participants'] ??
                                                          []);
                                              if (participants
                                                  .contains(targetUserId)) {
                                                chatId = doc.id;
                                                break;
                                              }
                                            }

                                            if (chatId == null) {
                                              final docRef =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('chats')
                                                      .add({
                                                'participants': [
                                                  currentUid,
                                                  targetUserId
                                                ],
                                                'lastMessage': '',
                                                'lastMessageTime': FieldValue
                                                    .serverTimestamp(),
                                                'isLocked': false,
                                              });
                                              chatId = docRef.id;
                                            }

                                            if (context.mounted) {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          ChatScreen(
                                                              chatId: chatId!,
                                                              otherUserId:
                                                                  name)));
                                            }
                                          },
                                          icon: const Icon(Icons.message,
                                              color: Colors.white),
                                          label: const Text('Message',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  GlassTheme.primaryAccent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            const Divider(color: GlassTheme.glassBorder),
                            const SizedBox(height: 16),
                            const Text('Timeline',
                                style: TextStyle(
                                    color: GlassTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('authorId', isEqualTo: targetUserId)
                          .snapshots(),
                      builder: (context, postSnapshot) {
                        if (!postSnapshot.hasData)
                          return const SliverToBoxAdapter(
                              child:
                                  Center(child: CircularProgressIndicator()));
                        if (postSnapshot.data!.docs.isEmpty)
                          return const SliverToBoxAdapter(
                              child: Center(
                                  child: Text('No posts yet',
                                      style: TextStyle(
                                          color: GlassTheme.textSecondary))));

                        final docs = postSnapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = aData['createdAt'] as Timestamp?;
                          final bTime = bData['createdAt'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = docs[index];
                              return PostCard(
                                  post: doc.data() as Map<String, dynamic>,
                                  postId: doc.id);
                            },
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
