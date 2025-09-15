// lib/main.dart
import 'package:fashion_app/services/purchase_service.dart';
import 'package:fashion_app/ui/pages/profile_view.dart';
import 'package:fashion_app/ui/pages/tryon_wizard_view.dart';
import 'package:fashion_app/ui/viewmodels/plan_viewmodel.dart';
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// UI / Theme
import 'ui/theme.dart';

// Pages
import 'ui/pages/auth/auth_gate.dart';        // Login/Register yöneten kapı
import 'ui/pages/landing_view.dart';
import 'ui/pages/history_view.dart';

// ViewModels
import 'ui/viewmodels/tryon_viewmodel.dart';
import 'ui/viewmodels/history_viewmodel.dart';
import 'ui/viewmodels/auth_viewmodel.dart';

// Services / Repos
import 'services/auth_service.dart';
import 'data/fal_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env opsiyonel (yoksa app çalışmaya devam etsin)
  try { await dotenv.load(fileName: ".env"); } catch (_) {}

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FAL key: .env(FAL_KEY) -> --dart-define(FAL_KEY) -> ''
  final envKey = dotenv.maybeGet('FAL_KEY') ?? '';
  const defineKey = String.fromEnvironment('FAL_KEY', defaultValue: '');
  final falKey = envKey.isNotEmpty ? envKey : defineKey;

  // Not: Prod'da anahtarı istemciye gömmeyin; backend/proxy kullanın.
  final falRepo = FalDirectRepository(falKey: falKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TryonViewModel(falRepo)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel()..load()),
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => PlanViewModel()),
      ],
      child: const VtonApp(),
    ),
  );
}

class VtonApp extends StatelessWidget {
  const VtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTON',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),

      // Uygulama içi rotalar
      routes: {
        '/home'   : (_) => const LandingView(),
        '/tryon'  : (_) => const TryOnWizardView(),
        '/history': (_) => const HistoryView(),
        '/profile': (_) => const ProfileView(),
      },

      // İlk ekran → Auth durumuna göre Login/Register veya Landing
      home: const AuthGate(),
    );
  }
}
