import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('dtjkvnpu5', 'chatme', cache: false);

  Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }

  // الدالة الجديدة لرفع الفويسات
  Future<String?> uploadAudio(File audioFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(audioFile.path, resourceType: CloudinaryResourceType.Video),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Audio Error: $e");
      return null;
    }
  }
}
