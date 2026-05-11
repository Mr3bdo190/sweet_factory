import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  const UserProfileScreen({super.key, required this.targetUserId, required this.targetUserName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isFollowing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkIfFollowing();
  }

  void checkIfFollowing() async {
    if (currentUser == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).get();
    List followers = (doc.data() as Map<String, dynamic>)['followers'] ?? [];
    setState(() {
      isFollowing = followers.contains(currentUser!.uid);
      isLoading = false;
    });
  }

  void toggleFollow() async {
    if (currentUser == null) return;
    setState(() => isFollowing = !isFollowing);

    if (isFollowing) {
      // متابعة
      await FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).update({'followers': FieldValue.arrayUnion([currentUser!.uid])});
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'following': FieldValue.arrayUnion([widget.targetUserId])});
      
      // إرسال إشعار المتابعة
      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? 'مستخدم';
      await FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).collection('notifications').add({
        'title': 'متابع جديد 👤',
        'body': 'بدأ $myName في متابعتك!',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // إلغاء المتابعة
      await FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).update({'followers': FieldValue.arrayRemove([currentUser!.uid])});
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'following': FieldValue.arrayRemove([widget.targetUserId])});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.targetUserName, style: const TextStyle(color: Colors.purpleAccent)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(radius: 50, backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, size: 50, color: Colors.white)),
                const SizedBox(height: 16),
                Text(widget.targetUserName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                if (currentUser != null && currentUser!.uid != widget.targetUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey : Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10)),
                    onPressed: toggleFollow,
                    child: Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 10),
                const Text('البوستات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: widget.targetUserId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('مفيش بوستات.', style: TextStyle(color: Colors.grey)));

                      var docs = snapshot.data!.docs;
                      docs.sort((a, b) {
                        Timestamp? t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        Timestamp? t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        if (t1 == null || t2 == null) return 0;
                        return t2.compareTo(t1);
                      });

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var post = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFF1A1A2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(padding: const EdgeInsets.all(16.0), child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.white), textDirection: TextDirection.rtl)),
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
