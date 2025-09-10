import 'package:flutter/material.dart';
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
          case 0: // Ana Sayfa
            if (Navigator.canPop(context)) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
            break;

          case 1: // Dene
            widget.onTryNow();
            break;

          case 2: // Geçmiş
            await _BottomNavRoutes.toHistory(context);
            break;

          case 3: // Profil
            await _BottomNavRoutes.toProfile(context);
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: "Ana Sayfa"),
        NavigationDestination(icon: Icon(Icons.camera_rounded), label: "Dene"),
        NavigationDestination(icon: Icon(Icons.history_rounded), label: "Geçmiş"),
        NavigationDestination(icon: Icon(Icons.person_rounded), label: "Profil"),
      ],
    );
  }
}
