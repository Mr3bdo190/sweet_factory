import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/wateny_toast.dart';
import 'couple_chat_screen.dart';
import 'couple_gallery_screen.dart';
import 'couple_notes_screen.dart';
import 'couple_bucket_list_screen.dart';
import 'couple_other_screens.dart';

class CoupleHubScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const CoupleHubScreen(
      {super.key, required this.partnerId, required this.partnerName});

  @override
  State<CoupleHubScreen> createState() => _CoupleHubScreenState();
}

class _CoupleHubScreenState extends State<CoupleHubScreen> {
  late final String currentUserId;
  late final String coupleId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // تأمين الـ Logic: لو الـ partnerId هو نفسه الـ currentUserId، ده معناه في غلط في النقل
    // بنصلحه هنا احتياطي
    String finalPartnerId = widget.partnerId;

    final ids = [currentUserId, finalPartnerId];
    ids.sort(); // الترتيب ده هو اللي بيضمن إن الغرفة ثابتة للطرفين (A_B هي نفسها B_A)
    coupleId = ids.join('_');
    _initCoupleDoc();
  }

  Future<void> _initCoupleDoc() async {
    // التأكد إننا مش بنعمل Couple مع نفسنا
    if (currentUserId == widget.partnerId) {
      WatenyToast.show(context, 'Error', 'Cannot create a hub with yourself!');
      Navigator.pop(context);
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('couples').doc(coupleId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'participants': [currentUserId, widget.partnerId],
        'anniversary': FieldValue.serverTimestamp(),
        'streak': 0,
        'lastInteraction': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // استخدام merge للأمان
    }
  }

  Future<void> _updateMood() async {
    final moods = [
      '😊 Happy',
      '😢 Sad',
      '🥺 Missing You',
      '😡 Angry',
      '😴 Sleepy',
      '🥰 In Love'
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1525),
        title: const Text('How are you feeling?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moods
              .map((mood) => ListTile(
                    title: Text(mood,
                        style: const TextStyle(color: Colors.pinkAccent)),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('couples')
                          .doc(coupleId)
                          .update({
                        'moods.$currentUserId': mood,
                      });
                      if (mounted) Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _updatePetName() async {
    final controller = TextEditingController(text: 'Partner');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1525),
        title:
            const Text('Change Pet Name', style: TextStyle(color: Colors.pink)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'e.g. Honey, Babe',
              hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .update({
                'petNames.$currentUserId': controller.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLocation() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1525),
        title: const Text('Update Location',
            style: TextStyle(color: Colors.lightBlueAccent)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'e.g. At Work, Home',
              hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .update({
                'location.$currentUserId': controller.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGift() async {
    final gifts = [
      {'icon': '🌹', 'name': 'Rose'},
      {'icon': '🍫', 'name': 'Chocolate'},
      {'icon': '🧸', 'name': 'Teddy Bear'},
      {'icon': '💍', 'name': 'Ring'},
    ];
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1525),
        title: const Text('Send a Gift',
            style: TextStyle(color: Colors.redAccent)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: gifts
              .map((gift) => GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('couples')
                          .doc(coupleId)
                          .collection('chat')
                          .add({
                        'senderId': currentUserId,
                        'text': 'Sent you a ${gift['name']} ${gift['icon']}',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        WatenyToast.show(
                            context, 'Gift Sent', 'Your partner will love it!',
                            icon: Icons.card_giftcard);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(gift['icon']!,
                            style: const TextStyle(fontSize: 40)),
                        Text(gift['name']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _sendThinkingOfYou() async {
    await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('chat')
        .add({
      'senderId': currentUserId,
      'text': 'Thinking of you... ❤️',
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      WatenyToast.show(
          context, 'Sent', 'Your partner knows you are thinking of them!',
          icon: Icons.favorite);
    }
  }

  Future<void> _breakup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1525),
        title:
            const Text('Breakup?', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
            'Are you sure you want to unlink? This will remove your partner status.',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Breakup')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'partnerId': FieldValue.delete(),
        'relationshipStartDate': FieldValue.delete(),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.partnerId)
          .update({
        'partnerId': FieldValue.delete(),
        'relationshipStartDate': FieldValue.delete(),
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118), // Deep romantic background
      appBar: AppBar(
        title: Text('You & ${widget.partnerName}',
            style: const TextStyle(
                fontFamily: 'Cursive', fontSize: 28, color: Colors.pinkAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // تم إزالة زرار الإعدادات الوهمي
          IconButton(
              icon: const Icon(Icons.heart_broken, color: Colors.grey),
              onPressed: _breakup),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            final myMood = data['moods']?[currentUserId] ?? 'Unknown';
            final partnerMood = data['moods']?[widget.partnerId] ?? 'Unknown';
            final streak = data['streak'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top Status Card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.pinkAccent,
                                    child: Icon(Icons.person,
                                        color: Colors.white)),
                                const SizedBox(height: 8),
                                const Text('Me',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(myMood,
                                    style: const TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.pinkAccent, size: 40),
                                Text('🔥 $streak Days',
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.pinkAccent,
                                    child: Icon(Icons.person,
                                        color: Colors.white)),
                                const SizedBox(height: 8),
                                Text(widget.partnerName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(partnerMood,
                                    style: const TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid of Features
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                          Icons.message, 'Couple Chat', Colors.purpleAccent,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CoupleChatScreen(
                                    coupleId: coupleId,
                                    partnerName: widget.partnerName)));
                      }),
                      _buildFeatureCard(
                          Icons.photo_album, 'Gallery', Colors.blueAccent, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CoupleGalleryScreen(coupleId: coupleId)));
                      }),
                      _buildFeatureCard(Icons.favorite, 'Thinking of You',
                          Colors.pinkAccent, _sendThinkingOfYou),
                      _buildFeatureCard(Icons.mood, 'Mood Tracker',
                          Colors.orangeAccent, _updateMood),
                      _buildFeatureCard(
                          Icons.calendar_month, 'Calendar', Colors.greenAccent,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CoupleCalendarScreen(coupleId: coupleId)));
                      }),
                      _buildFeatureCard(
                          Icons.note_alt, 'Sticky Notes', Colors.yellowAccent,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CoupleNotesScreen(coupleId: coupleId)));
                      }),
                      _buildFeatureCard(
                          Icons.list_alt, 'Bucket List', Colors.tealAccent, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CoupleBucketListScreen(
                                    coupleId: coupleId)));
                      }),
                      _buildFeatureCard(Icons.question_answer, 'Daily Quiz',
                          Colors.cyanAccent, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CoupleQuizScreen(coupleId: coupleId)));
                      }),
                      _buildFeatureCard(Icons.card_giftcard, 'Virtual Gifts',
                          Colors.redAccent, _sendGift),
                      _buildFeatureCard(Icons.track_changes, 'Couple Goals',
                          Colors.indigoAccent, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CoupleGoalsScreen(coupleId: coupleId)));
                      }),
                      _buildFeatureCard(Icons.location_on, 'Location',
                          Colors.lightBlueAccent, _updateLocation),
                      _buildFeatureCard(Icons.text_fields, 'Pet Names',
                          Colors.pink, _updatePetName),
                    ],
                  )
                ],
              ),
            );
          }),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
