import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/glass_theme.dart';

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('settings').doc('versioning').get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final latestVersion = data['latestVersion'] as String?;
      final downloadUrl = data['downloadUrl'] as String?;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      if (latestVersion == null || downloadUrl == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadUrl, forceUpdate);
        }
      }
    } catch (e) {
      debugPrint('Update Check Failed: $e');
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latest.length; i++) {
      if (i >= current.length) return true; // latest has more subversions e.g. 1.0 vs 1.0.1
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String url, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GlassTheme.backgroundDark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GlassTheme.glassBorder, width: 1.5),
              boxShadow: [
                BoxShadow(color: GlassTheme.primaryAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update, size: 64, color: GlassTheme.primaryAccent),
                const SizedBox(height: 16),
                const Text(
                  'Update Available!',
                  style: TextStyle(color: GlassTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Version $version is now available. You are using an older version. Please update to enjoy the latest features and bug fixes.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GlassTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Update Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (!forceUpdate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later', style: TextStyle(color: GlassTheme.textSecondary)),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
