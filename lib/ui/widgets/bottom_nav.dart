import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';           // ⬅️ eklendi
import 'package:fashion_app/ui/pages/profile_view.dart';
import 'package:fashion_app/ui/pages/history_view.dart';

class LandingBottomNav extends StatefulWidget {
  final VoidCallback onTryNow;
  const LandingBottomNav({super.key, required this.onTryNow});

  @override
  State<LandingBottomNav> createState() => _LandingBottomNavState();
}

class _BottomNavRoutes {
  static Future<void> toProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileView()),
    );
  }

  static Future<void> toHistory(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryView()),
    );
  }
}

class _LandingBottomNavState extends State<LandingBottomNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) async {
        setState(() => _index = i);

        switch (i) {
          case 0: // Home
            if (Navigator.canPop(context)) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
            break;
          case 1: // Try
            widget.onTryNow();
            break;
          case 2: // History
            await _BottomNavRoutes.toHistory(context);
            break;
          case 3: // Profile
            await _BottomNavRoutes.toProfile(context);
            break;
        }
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_rounded),    label: tr('nav.home')),
        NavigationDestination(icon: const Icon(Icons.camera_rounded),  label: tr('nav.try')),
        NavigationDestination(icon: const Icon(Icons.history_rounded), label: tr('nav.history')),
        NavigationDestination(icon: const Icon(Icons.person_rounded),  label: tr('nav.profile')),
      ],
    );
  }
}
