import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleBucketListScreen extends StatefulWidget {
  final String coupleId;
  const CoupleBucketListScreen({super.key, required this.coupleId});

  @override
  State<CoupleBucketListScreen> createState() => _CoupleBucketListScreenState();
}

class _CoupleBucketListScreenState extends State<CoupleBucketListScreen> {
  final _itemController = TextEditingController();

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('bucket_list').add({
      'title': _itemController.text.trim(),
      'isCompleted': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _itemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1118),
      appBar: AppBar(title: const Text('Bucket List', style: TextStyle(color: Colors.tealAccent)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _itemController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Add an adventure...', hintStyle: TextStyle(color: Colors.white54)))),
                IconButton(icon: const Icon(Icons.add_task, color: Colors.tealAccent), onPressed: _addItem)
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('bucket_list').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return CheckboxListTile(
                      title: Text(data['title'] ?? '', style: TextStyle(color: Colors.white, decoration: data['isCompleted'] ? TextDecoration.lineThrough : null)),
                      value: data['isCompleted'] ?? false,
                      activeColor: Colors.tealAccent,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('bucket_list').doc(docs[index].id).update({'isCompleted': val});
                      },
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
