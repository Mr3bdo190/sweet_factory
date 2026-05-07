import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/main_screen.dart';
import '../screens/home/create_post_screen.dart';
import '../screens/home/create_story_screen.dart';
import '../screens/home/story_viewer_screen.dart';
import '../screens/chat/inbox_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/couple/couple_hub_screen.dart';
import '../screens/couple/couple_chat_screen.dart';
import '../screens/couple/couple_gallery_screen.dart';
import '../screens/couple/couple_notes_screen.dart';
import '../screens/couple/couple_bucket_list_screen.dart';
import '../screens/couple/couple_other_screens.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String mainFeed = '/main';
  static const String createPost = '/create-post';
  static const String createStory = '/create-story';
  static const String storyViewer = '/story-viewer';
  static const String inbox = '/inbox';
  static const String explore = '/explore';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String coupleHub = '/couple-hub';
  static const String coupleChat = '/couple-chat';
  static const String coupleGallery = '/couple-gallery';
  static const String coupleNotes = '/couple-notes';
  static const String coupleBucketList = '/couple-bucket-list';
  static const String coupleCalendar = '/couple-calendar';
  static const String adminDashboard = '/admin-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String name = settings.name ?? '';

    if (name == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
    if (name == login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
    if (name == register) {
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    }
    if (name == mainFeed) {
      return MaterialPageRoute(builder: (_) => const MainFeedScreen());
    }
    if (name == createPost) {
      return MaterialPageRoute(builder: (_) => const CreatePostScreen());
    }
    if (name == createStory) {
      return MaterialPageRoute(builder: (_) => const CreateStoryScreen());
    }
    if (name == storyViewer) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          story: args?['story'] ?? {},
          storyId: args?['storyId'] ?? '',
        ),
      );
    }
    if (name == inbox) {
      return MaterialPageRoute(builder: (_) => const InboxScreen());
    }
    if (name == explore) {
      return MaterialPageRoute(builder: (_) => const ExploreScreen());
    }
    if (name == notifications) {
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    }
    if (name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    }
    if (name == editProfile) {
      return MaterialPageRoute(builder: (_) => const EditProfileScreen());
    }
    if (name == coupleHub) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CoupleHubScreen(
          partnerId: args?['partnerId'] ?? '',
          partnerName: args?['partnerName'] ?? 'Partner',
        ),
      );
    }
    if (name == coupleChat) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CoupleChatScreen(
          coupleId: args?['coupleId'] ?? '',
          partnerName: args?['partnerName'] ?? '',
        ),
      );
    }
    if (name == coupleGallery) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CoupleGalleryScreen(coupleId: args?['coupleId'] ?? ''),
      );
    }
    if (name == coupleNotes) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CoupleNotesScreen(coupleId: args?['coupleId'] ?? ''),
      );
    }
    if (name == coupleBucketList) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) =>
            CoupleBucketListScreen(coupleId: args?['coupleId'] ?? ''),
      );
    }
    if (name == coupleCalendar) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CoupleCalendarScreen(coupleId: args?['coupleId'] ?? ''),
      );
    }
    if (name == adminDashboard) {
      return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
    }

    // Default route
    return MaterialPageRoute(
      builder: (ctx) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'No route defined: $name',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
