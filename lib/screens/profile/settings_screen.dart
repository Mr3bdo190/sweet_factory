import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../routes/app_routes.dart';
import '../../widgets/wateny_toast.dart';

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
  bool _appLockEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final prefs = await SharedPreferences.getInstance();

      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        setState(() {
          _privateAccount = data['privateAccount'] ?? false;
          _showActiveStatus = data['showActiveStatus'] ?? true;
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _privacyLevel = data['defaultPrivacy'] ?? 'Public';
          _appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({key: value});
    }
  }

  Future<void> _deleteAccount() async {
    // كود حقيقي لحذف الحساب
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: GlassTheme.backgroundDark,
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.redAccent)),
                content: const Text(
                    'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
                    style: TextStyle(color: GlassTheme.textPrimary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      try {
                        // مسح الداتا من قاعدة البيانات
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .delete();
                        // مسح الحساب من Auth
                        await user.delete();
                        if (mounted)
                          Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.login, (route) => false);
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted)
                          WatenyToast.show(context, 'Error',
                              'Please re-login before deleting your account for security reasons.',
                              icon: Icons.error);
                      }
                    },
                    child: const Text('Delete Permanently'),
                  ),
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: GlassTheme.backgroundDark,
          body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin =
        FirebaseAuth.instance.currentUser?.email == 'mr3bdo@wateny.com';

    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Privacy & Safety'),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile('Private Account',
                    'Only followers can see posts', _privateAccount, (val) {
                  setState(() => _privateAccount = val);
                  _updateSetting('privateAccount', val);
                }, Icons.lock_person),
                const Divider(height: 1, color: GlassTheme.glassBorderLight),
                _buildSwitchTile(
                    'Active Status',
                    'Let others see when you are online',
                    _showActiveStatus, (val) {
                  setState(() => _showActiveStatus = val);
                  _updateSetting('showActiveStatus', val);
                }, Icons.circle, iconColor: Colors.greenAccent),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                    'Push Notifications',
                    'Receive alerts on your phone',
                    _notificationsEnabled, (val) {
                  setState(() => _notificationsEnabled = val);
                  _updateSetting('notificationsEnabled', val);
                }, Icons.notifications_active),
                const Divider(height: 1, color: GlassTheme.glassBorderLight),
                _buildSwitchTile('App Lock (PIN)', 'Require PIN to open Wateny',
                    _appLockEnabled, (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('appLockEnabled', val);
                  setState(() => _appLockEnabled = val);
                }, Icons.security),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Data & Storage'),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.cleaning_services,
                  color: GlassTheme.textPrimary),
              title: const Text('Clear App Cache',
                  style: TextStyle(color: GlassTheme.textPrimary)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: GlassTheme.textSecondary),
              onTap: () {
                PaintingBinding.instance.imageCache.clear();
                WatenyToast.show(
                    context, 'Cleaned!', 'App cache cleared successfully.',
                    icon: Icons.check_circle);
              },
            ),
          ),

          if (isAdmin) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Admin Zone', color: Colors.amber),
            GlassContainer(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading:
                    const Icon(Icons.admin_panel_settings, color: Colors.amber),
                title: const Text('Admin Dashboard',
                    style: TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.amber),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen())),
              ),
            ),
          ],

          const SizedBox(height: 32),
          // منطقة الخطر (تسجيل الخروج وحذف الحساب)
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orangeAccent),
                  title: const Text('Log Out',
                      style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.login, (route) => false);
                  },
                ),
                const Divider(height: 1, color: GlassTheme.glassBorderLight),
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Delete Account',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                  onTap: _deleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {Color color = GlassTheme.primaryAccent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value,
      Function(bool) onChanged, IconData icon,
      {Color? iconColor}) {
    return SwitchListTile(
      secondary: Icon(icon, color: iconColor ?? GlassTheme.textPrimary),
      title: Text(title,
          style: const TextStyle(
              color: GlassTheme.textPrimary, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(color: GlassTheme.textSecondary, fontSize: 12)),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: GlassTheme.primaryAccent,
      inactiveThumbColor: GlassTheme.textSecondary,
      inactiveTrackColor: GlassTheme.surfaceLight,
      onChanged: onChanged,
    );
  }
}
