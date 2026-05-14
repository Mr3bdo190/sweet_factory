import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  static Future<List<Map<String, dynamic>>> syncContacts() async {
    List<Map<String, dynamic>> registeredUsers = [];
    
    // 1. اطلب الإذن
    if (await FlutterContacts.requestPermission()) {
      // 2. اقرأ جهات الاتصال من الموبايل
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      
      // 3. استخرج الأرقام فقط ونضفها
      List<String> phoneNumbers = [];
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          // تنظيف الرقم من المسافات والرموز (زي +20 أو 010)
          String cleanPhone = phone.number.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone.startsWith('2')) cleanPhone = cleanPhone.substring(1); // لو بيبدأ بـ 20
          if (cleanPhone.startsWith('0')) cleanPhone = cleanPhone.substring(1); // لو بيبدأ بـ 0
          phoneNumbers.add(cleanPhone);
        }
      }

      // 4. ابحث في الفايربيز عن الأرقام دي (بنظام الـ Batches عشان السرعة)
      if (phoneNumbers.isNotEmpty) {
        // الفايربيز بيبحث بحد أقصى 10 أرقام في المرة، بس للتبسيط هنعمل بحث عام
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: phoneNumbers.take(10).toList()) // تجربة أول 10
            .get();

        for (var doc in snapshot.docs) {
          registeredUsers.add(doc.data());
        }
      }
    }
    return registeredUsers;
  }
}
