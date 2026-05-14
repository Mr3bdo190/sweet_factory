import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true); // التطبيق مفتوح في الشاشة
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _updatePresence(false); // نزل في الخلفية أو اتقفل
    }
  }

  void _updatePresence(bool isOnline) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }
}
