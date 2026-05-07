import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic _cloudinary;

  CloudinaryService._internal() {
    // Note: Update with actual Cloudinary credentials
    _cloudinary = CloudinaryPublic(
      'dtjkvnpu5', // Replace with your actual cloud name if different
      'chatme', // Replace with your actual upload preset if different
      cache: false,
    );
  }

  /// Uploads an image file to Cloudinary and returns the secure URL
  Future<String?> uploadImage(File imageFile,
      {String folder = 'wateny_uploads'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  /// Uploads a video file to Cloudinary
  Future<String?> uploadVideo(File videoFile,
      {String folder = 'wateny_videos'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoFile.path,
          resourceType: CloudinaryResourceType.Video,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Video Upload Error: $e');
      return null;
    }
  }

  Future<String?> uploadRawFile(File rawFile,
      {String folder = 'wateny_raw'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          rawFile.path,
          resourceType: CloudinaryResourceType.Raw,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Raw Upload Error: $e');
      return null;
    }
  }

    Future<String?> uploadAudio(File audioFile,
        {String folder = 'weteny_audio'}) async {
      try {
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            audioFile.path,
            resourceType: CloudinaryResourceType.Video, // Cloudinary treats audio as video
            folder: folder,
          ),
        );
        return response.secureUrl;
      } catch (e) {
        debugPrint('Cloudinary Audio Upload Error: $e');
        return null;
      }
    }
}
