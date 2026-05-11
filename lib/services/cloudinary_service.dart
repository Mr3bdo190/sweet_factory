import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // بيانات حسابك الحقيقية
  final cloudinary = CloudinaryPublic('dtjkvnpu5', 'chatme', cache: false);

  Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl; // رابط الصورة المباشر
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }
}
