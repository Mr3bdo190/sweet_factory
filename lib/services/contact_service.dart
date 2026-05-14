import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  static Future<List<Map<String, dynamic>>> syncContacts() async {
    List<Map<String, dynamic>> registeredUsers = [];
    
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      
      // تنظيف وتبسيط كل الأرقام اللي على الموبايل
      Set<String> myPhoneBook = {};
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          String clean = phone.number.replaceAll(RegExp(r'\D'), '');
          if (clean.length >= 10) {
            // بناخد آخر 10 أرقام عشان نتفادى كود الدولة (+20)
            myPhoneBook.add(clean.substring(clean.length - 10));
          }
        }
      }

      // جلب كل مستخدمي التطبيق (للمقارنة)
      var snapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var doc in snapshot.docs) {
        var userData = doc.data();
        String dbPhone = userData['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
        
        if (dbPhone.length >= 10) {
          String shortDbPhone = dbPhone.substring(dbPhone.length - 10);
          if (myPhoneBook.contains(shortDbPhone)) {
            registeredUsers.add(userData);
          }
        }
      }
    }
    return registeredUsers;
  }
}
