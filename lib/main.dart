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
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// UI / Theme
import 'ui/theme.dart';

// Pages
import 'ui/pages/auth/auth_gate.dart';
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

  // .env opsiyonel
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
        // 1) FirebaseAuth durumunu tüm ağaçta erişilebilir yap
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),

        ChangeNotifierProvider(create: (_) => TryonViewModel(falRepo)),
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => PlanViewModel()),

        // 2) HistoryViewModel'i mevcut kullanıcıyla başlat
        //    (login yoksa 'anon' ile güvenli başlatır)
        ChangeNotifierProxyProvider<User?, HistoryViewModel>(
          create: (_) =>
              HistoryViewModel(userKey: FirebaseAuth.instance.currentUser?.uid ?? 'anon')
                ..load(),
          update: (context, user, vm) {
            final uid = user?.uid ?? 'anon';
            // Oturum değiştiyse HistoryViewModel'i güncelle
            if (vm != null && vm.userKey != uid) {
              vm.setUser(uid); // setUser içinde items temizlenip load() çağrılıyor
            }
            return vm!;
          },
        ),
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
