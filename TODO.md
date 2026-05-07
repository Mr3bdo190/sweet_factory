# Firebase Integration Plan - Sweet Factory Social App

## **1. Dependencies (Done)**
- [x] pubspec.yaml → firebase_core, firebase_auth, cloud_firestore
- [x] `flutter pub get`

## **2. Delete Mock Data**
- [ ] Remove lib/services/mock_data_service.dart
- [ ] Clean lib/core/constants.dart (mock lists)
- [ ] Update all screens (feed_screen, profile_screen, etc.)

## **3. Firebase Services (NEW)**
- [ ] lib/services/auth_service.dart → signIn/createUser
- [ ] lib/services/firestore_service.dart → posts/users/chats
- [ ] lib/services/storage_service.dart → images/videos

## **4. Auth Screens**
- [ ] login_screen.dart → FirebaseAuth.signInWithEmailAndPassword
- [ ] signup_screen.dart → FirebaseAuth.createUserWithEmailAndPassword
- [ ] Add email verification

## **5. Real-time Data**
- [ ] feed_screen.dart → StreamBuilder<QuerySnapshot> posts
- [ ] profile_screen.dart → Firestore user doc
- [ ] chat → Firestore chat collections

## **6. Test & Deploy**
- [ ] `flutterfire configure` (CLI setup)
- [ ] Test login/register/posts
- [ ] `flutter build web --release`
- [ ] Firebase Hosting deploy

**Current Progress**: 25% (Dependencies ready)

**Next Step**: Delete mock data + create services
