import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Push Bildirimleri'),
            subtitle: const Text('Kampanya ve sonuç hatırlatmaları'),
            value: vm.pushNotifications,
            onChanged: (v) => vm.setPushNotifications(v),
          ),
          const SizedBox(height: 12),
          const Text('Not: iOS/Android sistem izinleri ayrıca istenebilir.'),
        ],
      ),
    );
  }
}
