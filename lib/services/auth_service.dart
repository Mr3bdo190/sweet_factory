import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تسجيل الدخول
  Future<String> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ غير معروف';
    } catch (e) {
      return e.toString();
    }
  }

  // إنشاء حساب جديد وحفظ البيانات
  Future<String> registerUser({required String name, required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // حفظ بيانات المستخدم في قاعدة البيانات (Firestore)
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'profilePic': '', // هنضيفها بعدين في البروفايل
        'followers': [],
        'following': [],
      });

      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ غير معروف';
    } catch (e) {
      return e.toString();
    }
  }

  // تسجيل الخروج
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
