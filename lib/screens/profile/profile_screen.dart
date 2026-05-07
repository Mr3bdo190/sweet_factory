import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/glass_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/post_card.dart';
import '../../widgets/glass_container.dart';
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
      backgroundColor: GlassTheme.backgroundDark,
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
                final bio = userData['bio'] ?? 'No bio added yet.';
                final profileImageUrl = userData['profileImageUrl'];
                final coverImageUrl = userData['coverImageUrl'];
                final friendsCount =
                    (userData['friends'] as List?)?.length ?? 0;
                final partnerId = userData['partnerId'];
                final partnerRequests =
                    List<String>.from(userData['partnerRequests'] ?? []);
                final joinDate = userData['createdAt'] != null
                    ? (userData['createdAt'] as Timestamp).toDate()
                    : DateTime.now();

                return CustomScrollView(
                  slivers: [
                    // الـ AppBar الشفاف اللي بيظهر لما تعمل Scroll
                    SliverAppBar(
                      pinned: true,
                      backgroundColor:
                          GlassTheme.backgroundDark.withValues(alpha: 0.9),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      actions: [
                        if (isMe)
                          IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen())),
                          ),
                      ],
                    ),

                    // الجزء العلوي (الكوفر والصورة والمعلومات)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Stack لدمج الكوفر مع الصورة الشخصية
                          SizedBox(
                            height: 250,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // الكوفر
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: GlassTheme.surfaceLight,
                                      image: coverImageUrl != null &&
                                              coverImageUrl
                                                  .toString()
                                                  .isNotEmpty
                                          ? DecorationImage(
                                              image:
                                                  NetworkImage(coverImageUrl),
                                              fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: (coverImageUrl == null ||
                                            coverImageUrl.toString().isEmpty)
                                        ? const Icon(Icons.panorama,
                                            size: 50,
                                            color: GlassTheme.textMuted)
                                        : null,
                                  ),
                                ),
                                // الصورة الشخصية البارزة
                                Positioned(
                                  bottom: 0,
                                  left: 20, // لمحاذاة زي فيسبوك
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: GlassTheme.backgroundDark,
                                      shape: BoxShape.circle,
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
                                ),
                              ],
                            ),
                          ),

                          // بيانات اليوزر والأزرار
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: GlassTheme.textPrimary)),
                                const SizedBox(height: 8),
                                Text(bio,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: GlassTheme.textSecondary)),
                                const SizedBox(height: 16),

                                // صف الأزرار الاحترافي
                                _buildActionButtons(
                                    context,
                                    isMe,
                                    partnerId,
                                    partnerRequests,
                                    currentUserId!,
                                    targetUserId,
                                    name,
                                    friendsCount),

                                const SizedBox(height: 24),
                                const Divider(
                                    color: GlassTheme.glassBorderLight),
                                const SizedBox(height: 16),

                                // كروت المعلومات (About Section)
                                const Text('About',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: GlassTheme.textPrimary)),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.people_alt_outlined,
                                    '$friendsCount Friends'),
                                _buildInfoRow(Icons.calendar_month_outlined,
                                    'Joined ${timeago.format(joinDate)}'),
                                if (partnerId != null)
                                  _buildInfoRow(
                                      Icons.favorite, 'In a Relationship',
                                      color: Colors.pinkAccent),

                                const SizedBox(height: 16),
                                const Divider(
                                    color: GlassTheme.glassBorderLight),
                                const SizedBox(height: 16),
                                const Text('Posts',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: GlassTheme.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // التايم لاين (المنشورات)
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
                        if (postSnapshot.data!.docs.isEmpty) {
                          return const SliverToBoxAdapter(
                              child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                                child: Text('No posts to show',
                                    style: TextStyle(
                                        color: GlassTheme.textSecondary))),
                          ));
                        }

                        final docs = postSnapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aTime =
                              (a.data() as Map)['createdAt'] as Timestamp?;
                          final bTime =
                              (b.data() as Map)['createdAt'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return PostCard(
                                  post: docs[index].data()
                                      as Map<String, dynamic>,
                                  postId: docs[index].id);
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

  // أزرار الأكشن السريعة (Facebook Style)
  Widget _buildActionButtons(
      BuildContext context,
      bool isMe,
      String? partnerId,
      List<String> partnerRequests,
      String currentUid,
      String targetUid,
      String targetName,
      int friendsCount) {
    if (isMe) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {}, // إضافة للقصة
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add to Story'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.secondaryAccent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.surfaceLight),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Logic الإضافة كصديق السريع
                    final targetDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetUid)
                        .get();
                    final targetFriends =
                        List<String>.from(targetDoc.data()?['friends'] ?? []);
                    if (targetFriends.contains(currentUid)) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(targetUid)
                          .update({
                        'friends': FieldValue.arrayRemove([currentUid])
                      });
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .update({
                        'friends': FieldValue.arrayRemove([targetUid])
                      });
                      if (context.mounted)
                        WatenyToast.show(context, 'Unfriended',
                            'You are no longer friends.');
                    } else {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(targetUid)
                          .update({
                        'friends': FieldValue.arrayUnion([currentUid])
                      });
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .update({
                        'friends': FieldValue.arrayUnion([targetUid])
                      });
                      if (context.mounted)
                        WatenyToast.show(
                            context, 'Friend Added', 'You are now friends!',
                            icon: Icons.check_circle);
                    }
                  },
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Friend'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.secondaryAccent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Logic فتح الشات
                    final query = await FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: currentUid)
                        .get();
                    String? chatId;
                    for (var doc in query.docs) {
                      final participants =
                          List<String>.from(doc['participants'] ?? []);
                      if (participants.contains(targetUid)) {
                        chatId = doc.id;
                        break;
                      }
                    }
                    if (chatId == null) {
                      final docRef = await FirebaseFirestore.instance
                          .collection('chats')
                          .add({
                        'participants': [currentUid, targetUid],
                        'lastMessage': '',
                        'lastMessageTime': FieldValue.serverTimestamp(),
                        'isLocked': false,
                      });
                      chatId = docRef.id;
                    }
                    if (context.mounted)
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  chatId: chatId!, otherUserId: targetName)));
                  },
                  icon: const Icon(Icons.message, color: Colors.white),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.surfaceLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // زر الارتباط
          if (partnerId == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (partnerRequests.contains(currentUid)) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetUid)
                        .update({
                      'partnerRequests': FieldValue.arrayRemove([currentUid])
                    });
                    if (context.mounted)
                      WatenyToast.show(
                          context, 'Canceled', 'Request canceled.');
                  } else {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetUid)
                        .update({
                      'partnerRequests': FieldValue.arrayUnion([currentUid])
                    });
                    if (context.mounted)
                      WatenyToast.show(context, 'Sent', 'Partner request sent!',
                          icon: Icons.favorite);
                  }
                },
                icon: Icon(
                    partnerRequests.contains(currentUid)
                        ? Icons.cancel
                        : Icons.favorite,
                    color: Colors.white),
                label: Text(
                    partnerRequests.contains(currentUid)
                        ? 'Cancel Request'
                        : 'Request Partnership 💍',
                    style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: partnerRequests.contains(currentUid)
                        ? GlassTheme.surfaceLight
                        : Colors.pinkAccent),
              ),
            )
          else if (partnerId == currentUid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CoupleHubScreen(
                            partnerId: targetUid, partnerName: targetName))),
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text('Open Couple Hub 💖'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text,
      {Color color = GlassTheme.textSecondary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(text,
              style:
                  const TextStyle(color: GlassTheme.textPrimary, fontSize: 16)),
        ],
      ),
    );
  }
}
