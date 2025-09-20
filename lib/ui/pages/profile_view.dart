import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/services/auth_service.dart';
import 'package:fashion_app/services/local_avatar_service.dart';
import 'package:fashion_app/ui/pages/auth/reset_password_view.dart';
import 'package:fashion_app/ui/pages/settings/delete_account_wizard_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // ⬅️ eklendi

// UI widgets
import 'package:fashion_app/ui/widgets/profile_header.dart';
import 'package:fashion_app/ui/widgets/section_title.dart';
import 'package:fashion_app/ui/widgets/setting_tile.dart';

// AuthGate
import 'package:fashion_app/ui/pages/auth/auth_gate.dart';

// Ayar VM
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';

// Sayfalar
import 'settings/profile_edit_view.dart';
import 'settings/privacy_settings_view.dart';
import 'settings/notifications_view.dart';
import 'settings/plan_view.dart';
import 'settings/help_support_view.dart';
import 'settings/about_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<Map<String, dynamic>?> _userFuture;
  String? _localAvatarPath;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> _loadLocalAvatar() async {
    _localAvatarPath = await LocalAvatarService.getSavedPath(userId: _userId);
  }

  Future<Map<String, dynamic>?> _loadUserData() async {
    await _loadLocalAvatar();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return snap.data();
  }

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().load();
    });
  }

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return v == key ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    const appVersion = '1.0.0';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('profile.title')),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(tr('profile.errors.not_found')));
          }

          final data = snapshot.data!;
          final name = data['name'] ?? '—';
          final email = data['email'] ?? '—';

          final planKey = (data['plan'] ?? 'free').toString();
          final planLabel = _trOr('profile.plan.$planKey', planKey.toUpperCase());

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              ProfileHeader(
                name: name,
                email: email,
                planLabel: planLabel,
                localAvatarPath: _localAvatarPath,
                userId: _userId,
                onAvatarChanged: (newPath) => setState(() => _localAvatarPath = newPath),
              ),
              const SizedBox(height: 16),

              SectionTitle(tr('profile.sections.account_security')),
              SettingTile(
                leading: Icons.badge_rounded,
                title: tr('profile.items.profile_info.title'),
                subtitle: tr('profile.items.profile_info.subtitle'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileEditView(currentName: name, currentEmail: email),
                  ),
                ),
              ),
              SettingTile(
                leading: Icons.security_outlined,
                title: tr('profile.items.privacy.title'),
                subtitle: tr('profile.items.privacy.subtitle'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsView())),
              ),
              SettingTile(
                leading: Icons.lock_rounded,
                title: tr('profile.items.reset_password.title'),
                subtitle: tr('profile.items.reset_password.subtitle'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordView())),
              ),
              SettingTile(
                leading: Icons.delete_forever_rounded,
                title: tr('profile.items.delete_account.title'),
                subtitle: tr('profile.items.delete_account.subtitle'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountWizardView())),
              ),
              Consumer<SettingsViewModel>(
                builder: (_, settings, __) => SettingTile.switcher(
                  leading: Icons.verified_user_rounded,
                  title: tr('profile.items.face_local_store.title'),
                  subtitle: tr('profile.items.face_local_store.subtitle'),
                  value: settings.faceLocalStore,
                  onChanged: (v) => settings.setFaceLocalStore(v),
                ),
              ),

              const SizedBox(height: 12),
              SectionTitle(tr('profile.sections.notifications')),
              SettingTile(
                leading: Icons.notifications_active_rounded,
                title: tr('profile.items.push_notifications.title'),
                subtitle: tr('profile.items.push_notifications.subtitle'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView())),
              ),

              const SizedBox(height: 12),
              SectionTitle(tr('profile.sections.subscription')),
              SettingTile(
                leading: Icons.workspace_premium_rounded,
                title: tr('profile.items.plan.title'),
                trailing: _Pill(text: planLabel),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanView())),
              ),

              const SizedBox(height: 12),
              SectionTitle(tr('profile.sections.other')),
              SettingTile(
                leading: Icons.help_center_rounded,
                title: tr('profile.items.help.title'),
                subtitle: tr('profile.items.help.subtitle'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportView())),
              ),
              SettingTile(
                leading: Icons.info_rounded,
                title: tr('profile.items.about.title'),
                subtitle: tr('profile.items.about.version', namedArgs: {'version': appVersion}),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutView())),
              ),

              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout_rounded, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                tr('profile.logout.confirm_title'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(tr('common.cancel')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(tr('profile.logout.confirm_action'),
                                          style: const TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (confirm == true) {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (_) => false,
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(tr('profile.logout.button')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
