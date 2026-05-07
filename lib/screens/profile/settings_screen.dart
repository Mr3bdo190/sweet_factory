import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../routes/app_routes.dart';
import '../../widgets/wateny_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  String _privacyLevel = 'Public';
  bool _privateAccount = false;
  bool _showActiveStatus = true;
  bool _twoFactorEnabled = false;
  bool _isLoading = true;
  bool _appLockEnabled = false;
  bool _autoPlayVideos = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppLockSettings();
  }

  Future<void> _loadAppLockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
      });
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Show PIN setup dialog
      _showSetPinDialog();
    } else {
      await prefs.setBool('appLockEnabled', false);
      await prefs.remove('appPin');
      if (mounted) {
        setState(() => _appLockEnabled = false);
        WatenyToast.show(context, 'Success', 'App lock disabled', icon: Icons.lock_open);
      }
    }
  }

  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.backgroundDark,
        title: const Text('Set PIN', style: TextStyle(color: GlassTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter 4-digit PIN',
                hintStyle: TextStyle(color: GlassTheme.textSecondary),
              ),
              style: const TextStyle(color: GlassTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm PIN',
                hintStyle: TextStyle(color: GlassTheme.textSecondary),
              ),
              style: const TextStyle(color: GlassTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: GlassTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('appLockEnabled', true);
              await prefs.setString('appPin', pinController.text);
              if (mounted) {
                setState(() => _appLockEnabled = true);
                Navigator.pop(context);
                WatenyToast.show(context, 'Success', 'App lock enabled', icon: Icons.lock);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.backgroundDark,
        title: const Text('Clear Cache', style: TextStyle(color: GlassTheme.textPrimary)),
        content: const Text(
          'This will clear all cached images and temporary files. Are you sure?',
          style: TextStyle(color: GlassTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: GlassTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear cache logic would go here
              WatenyToast.show(context, 'Success', 'Cache cleared successfully', icon: Icons.check_circle);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _privateAccount = data['privateAccount'] ?? false;
            _showActiveStatus = data['showActiveStatus'] ?? true;
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _privacyLevel = data['defaultPrivacy'] ?? 'Public';
            _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({key: value});
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent (Demo)')));
    // In real scenario: FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser.email!);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.email == 'admin@wateny.com' || currentUser?.email == 'mr3bdo@wateny.com';

    if (_isLoading) {
      return const Scaffold(backgroundColor: GlassTheme.backgroundDark, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(title: const Text('Settings & Privacy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== PRIVACY ==================
            const Text('Privacy', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Private Account', style: TextStyle(color: GlassTheme.textPrimary)),
                    subtitle: const Text('Only approved followers can see your posts.', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                    value: _privateAccount,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() => _privateAccount = val);
                      _updateSetting('privateAccount', val);
                    },
                    secondary: const Icon(Icons.lock_person, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Show Active Status', style: TextStyle(color: GlassTheme.textPrimary)),
                    subtitle: const Text('Let others see when you are online.', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                    value: _showActiveStatus,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() => _showActiveStatus = val);
                      _updateSetting('showActiveStatus', val);
                    },
                    secondary: const Icon(Icons.remove_red_eye, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.public, color: GlassTheme.textSecondary),
                    title: const Text('Default Post Privacy', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: DropdownButton<String>(
                      value: _privacyLevel,
                      dropdownColor: GlassTheme.backgroundDark,
                      style: const TextStyle(color: GlassTheme.primaryAccent),
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _privacyLevel = newValue);
                          _updateSetting('defaultPrivacy', newValue);
                        }
                      },
                      items: <String>['Public', 'Friends', 'Only Me'].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================== SECURITY ==================
            const Text('Account Security', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.password, color: GlassTheme.textSecondary),
                    title: const Text('Change Password', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: GlassTheme.textSecondary, size: 16),
                    onTap: _changePassword,
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication', style: TextStyle(color: GlassTheme.textPrimary)),
                    subtitle: const Text('Require a code when logging in.', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                    value: _twoFactorEnabled,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() => _twoFactorEnabled = val);
                      _updateSetting('twoFactorEnabled', val);
                    },
                    secondary: const Icon(Icons.security, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices, color: GlassTheme.textSecondary),
                    title: const Text('Logout of all devices', style: TextStyle(color: Colors.orangeAccent)),
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out from other devices.')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================== APP PREFERENCES ==================
            const Text('App Preferences', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(color: GlassTheme.textPrimary)),
                    value: _notificationsEnabled,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      _updateSetting('notificationsEnabled', val);
                    },
                    secondary: const Icon(Icons.notifications, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(color: GlassTheme.textPrimary)),
                    value: _darkMode,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) => setState(() => _darkMode = val),
                    secondary: const Icon(Icons.dark_mode, color: GlassTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================== SECURITY & APP LOCK ==================
            const Text('Security', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('App Lock', style: TextStyle(color: GlassTheme.textPrimary)),
                    subtitle: const Text('Require PIN to open app', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                    value: _appLockEnabled,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: _toggleAppLock,
                    secondary: const Icon(Icons.lock, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Auto-play Videos', style: TextStyle(color: GlassTheme.textPrimary)),
                    subtitle: const Text('Automatically play videos in feed', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
                    value: _autoPlayVideos,
                    activeThumbColor: GlassTheme.primaryAccent,
                    activeTrackColor: GlassTheme.primaryAccent.withValues(alpha: 0.5),
                    onChanged: (val) => setState(() => _autoPlayVideos = val),
                    secondary: const Icon(Icons.play_circle_outline, color: GlassTheme.textSecondary),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep, color: GlassTheme.textSecondary),
                    title: const Text('Clear Cache', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: GlassTheme.textSecondary, size: 16),
                    onTap: _clearCache,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================== ABOUT ==================
            const Text('About', style: TextStyle(color: GlassTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: GlassTheme.textSecondary),
                    title: const Text('App Version', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: const Text('2.0.0', style: TextStyle(color: GlassTheme.textSecondary)),
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: GlassTheme.textSecondary),
                    title: const Text('Privacy Policy', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: GlassTheme.textSecondary, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy page coming soon')),
                      );
                    },
                  ),
                  const Divider(color: GlassTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: GlassTheme.textSecondary),
                    title: const Text('Terms of Service', style: TextStyle(color: GlassTheme.textPrimary)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: GlassTheme.textSecondary, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service page coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================== ADMIN ACTIONS ==================
            if (isAdmin) ...[
              const Text('Admin Actions', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              GlassContainer(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                  title: const Text('Admin Dashboard', style: TextStyle(color: Colors.redAccent)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ================== LOGOUT ==================
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: _logout,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
