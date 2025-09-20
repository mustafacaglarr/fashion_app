import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(tr('notifications.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: Text(tr('notifications.push_title')),
            subtitle: Text(tr('notifications.push_subtitle')),
            value: vm.pushNotifications,
            onChanged: (v) => vm.setPushNotifications(v),
          ),
          const SizedBox(height: 12),
          Text(tr('notifications.note')),
        ],
      ),
    );
  }
}
