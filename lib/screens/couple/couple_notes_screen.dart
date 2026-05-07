import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoupleNotesScreen extends StatefulWidget {
  final String coupleId;
  const CoupleNotesScreen({super.key, required this.coupleId});

  @override
  State<CoupleNotesScreen> createState() => _CoupleNotesScreenState();
}

class _CoupleNotesScreenState extends State<CoupleNotesScreen> {
  final _noteController = TextEditingController();

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notes').add({
      'text': _noteController.text.trim(),
      'authorId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'color': Colors.yellowAccent.toARGB32(),
    });
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Sticky Notes', style: TextStyle(color: Colors.yellowAccent)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _noteController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Write a love note...', hintStyle: TextStyle(color: Colors.white54)))),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.yellowAccent, size: 40), onPressed: _addNote)
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notes').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Color(data['color'] ?? Colors.yellowAccent.toARGB32()).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2,2))]),
                      child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cursive')),
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
