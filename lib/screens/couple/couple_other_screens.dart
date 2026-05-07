import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/glass_theme.dart';

// ==========================================
// COUPLE CALENDAR SCREEN
// ==========================================
class CoupleCalendarScreen extends StatefulWidget {
  final String coupleId;
  const CoupleCalendarScreen({super.key, required this.coupleId});

  @override
  State<CoupleCalendarScreen> createState() => _CoupleCalendarScreenState();
}

class _CoupleCalendarScreenState extends State<CoupleCalendarScreen> {
  final _eventController = TextEditingController();

  Future<void> _addEvent() async {
    if (_eventController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('calendar').add({
      'title': _eventController.text.trim(),
      'date': FieldValue.serverTimestamp(),
      'authorId': FirebaseAuth.instance.currentUser!.uid,
    });
    _eventController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Calendar', style: TextStyle(color: Colors.greenAccent)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _eventController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Add an event/date...', hintStyle: TextStyle(color: Colors.white54)))),
                IconButton(icon: const Icon(Icons.event_available, color: Colors.greenAccent), onPressed: _addEvent)
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('calendar').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                      title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COUPLE GOALS SCREEN
// ==========================================
class CoupleGoalsScreen extends StatefulWidget {
  final String coupleId;
  const CoupleGoalsScreen({super.key, required this.coupleId});

  @override
  State<CoupleGoalsScreen> createState() => _CoupleGoalsScreenState();
}

class _CoupleGoalsScreenState extends State<CoupleGoalsScreen> {
  final _goalController = TextEditingController();

  Future<void> _addGoal() async {
    if (_goalController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('goals').add({
      'title': _goalController.text.trim(),
      'progress': 0, // Out of 100
      'timestamp': FieldValue.serverTimestamp(),
    });
    _goalController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Couple Goals', style: TextStyle(color: Colors.indigoAccent)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _goalController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'New goal (e.g. Vacation Trip)...', hintStyle: TextStyle(color: Colors.white54)))),
                IconButton(icon: const Icon(Icons.flag, color: Colors.indigoAccent), onPressed: _addGoal)
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('goals').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final progress = (data['progress'] ?? 0) as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: GlassTheme.glassWhite.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: progress / 100, backgroundColor: Colors.white24, color: Colors.indigoAccent),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$progress% Completed', style: const TextStyle(color: Colors.white70)),
                              TextButton(
                                onPressed: () {
                                  if (progress < 100) {
                                    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('goals').doc(docs[index].id).update({'progress': progress + 10});
                                  }
                                },
                                child: const Text('Add 10%', style: TextStyle(color: Colors.indigoAccent)),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COUPLE QUIZ SCREEN
// ==========================================
class CoupleQuizScreen extends StatefulWidget {
  final String coupleId;
  const CoupleQuizScreen({super.key, required this.coupleId});

  @override
  State<CoupleQuizScreen> createState() => _CoupleQuizScreenState();
}

class _CoupleQuizScreenState extends State<CoupleQuizScreen> {
  final List<String> questions = [
    "What is my favorite food?",
    "Where did we first meet?",
    "What do I love most about you?",
    "What is my dream travel destination?",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Daily Quiz', style: TextStyle(color: Colors.cyanAccent)), backgroundColor: Colors.transparent),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return Card(
            color: GlassTheme.glassWhite.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.cyanAccent),
              title: Text(questions[index], style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () {
                // Simplified: Posts the question into their chat to discuss
                FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('chat').add({
                  'senderId': FirebaseAuth.instance.currentUser!.uid,
                  'text': 'Quiz Time! 🧐\n${questions[index]}',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context); // Go back to hub
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz sent to chat!')));
              },
            ),
          );
        },
      ),
    );
  }
}
