import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// الدالة دي لازم تكون بره الكلاس عشان تشتغل والتطبيق مقفول
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // هنا بنستقبل الإشعار والتطبيق في الخلفية
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. طلب صلاحية إرسال الإشعارات من اليوزر
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. تفعيل الإشعارات المحلية
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    // تم التعديل هنا: استخدام initializationSettings كمعامل مسمى
    await _localNotifications.initialize(
      initializationSettings: initSettings,
    );

    // 3. الحصول على الـ Token (رقم تعريف جهاز اليوزر) وحفظه في الفايربيز
    String? token = await _fcm.getToken();
    _saveToken(token);

    // تحديث الـ Token لو اتغير
    _fcm.onTokenRefresh.listen(_saveToken);

    // 4. استقبال الإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 5. استقبال الإشعارات والتطبيق مقفول (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // حفظ الـ Token في الداتا بيز عشان نعرف نبعت للإشعار للشخص الصح
  void _saveToken(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
      });
    }
  }

  // إظهار الإشعار على الشاشة
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // تم التعديل هنا: استخدام المعاملات المسماة (id, title, body, notificationDetails)
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'wateny_channel', // ID القناة
            'Wateny Notifications', // اسم القناة
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}
