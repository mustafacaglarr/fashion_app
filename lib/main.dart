// lib/main.dart — easy_localization + Functions tabanlı Fal repo (Yol A)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/app_keys.dart';
import 'package:fashion_app/services/purchase_service.dart';
import 'package:fashion_app/services/tryon_quota_service_firebase.dart';
import 'package:fashion_app/ui/pages/profile_view.dart';
import 'package:fashion_app/ui/pages/settings/plan_view.dart';
import 'package:fashion_app/ui/pages/tryon_wizard_view.dart';
import 'package:fashion_app/ui/viewmodels/plan_viewmodel.dart';
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kReleaseMode; // 👈 debug/release ayırımı
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// i18n
import 'package:easy_localization/easy_localization.dart';

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
import 'data/fal_repository.dart'; // FalFunctionsRepository

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check — Debug: Debug provider, Release: Play Integrity (Android) / App Attest fallback (iOS)
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode ? AppleProvider.appAttestWithDeviceCheckFallback : AppleProvider.debug,
  );
  // İlk çalıştırmada loga düşen "App Check debug token"ı Firebase Console > App Check > Debug tokens’a eklemeyi unutma.

  await EasyLocalization.ensureInitialized();

  // Functions tabanlı Fal repo (API key client’a gömülmüyor)
  final falRepo = FalFunctionsRepository();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: MultiProvider(
        providers: [
          // 1) FirebaseAuth stream
          StreamProvider<User?>.value(
            value: FirebaseAuth.instance.authStateChanges(),
            initialData: FirebaseAuth.instance.currentUser,
          ),

          // 2) Tryon VM (Functions + Firestore kota servisi)
          ChangeNotifierProvider(
            create: (_) => TryonViewModel(
              falRepo,
              quotaService: TryOnQuotaService(
                auth: FirebaseAuth.instance,
                db: FirebaseFirestore.instance,
              ),
            ),
          ),

          ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
          ChangeNotifierProvider(create: (_) => SettingsViewModel()),
          ChangeNotifierProvider(create: (_) => PlanViewModel()),

          // 3) Satın alma
          ChangeNotifierProvider<PurchaseService>(
            create: (_) => PurchaseService()..init(),
          ),

          // 4) History VM (kullanıcı değişiminde reset+load)
          ChangeNotifierProxyProvider<User?, HistoryViewModel>(
            create: (_) => HistoryViewModel(
              userKey: FirebaseAuth.instance.currentUser?.uid ?? 'anon',
            )..load(),
            update: (context, user, vm) {
              final uid = user?.uid ?? 'anon';
              if (vm != null && vm.userKey != uid) {
                vm.setUser(uid);
              }
              return vm!;
            },
          ),
        ],
        child: const VtonApp(),
      ),
    ),
  );
}

class VtonApp extends StatelessWidget {
  const VtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,            // ✅
  scaffoldMessengerKey: rootMessengerKey,   // ✅

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      title: 'VTON',
      onGenerateTitle: (_) => tr('app_title'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),

      routes: {
        '/home': (_) => const LandingView(),
        '/tryon': (_) => const TryOnWizardView(),
        '/history': (_) => const HistoryView(),
        '/profile': (_) => const ProfileView(),
        '/upgrade': (_) => const PlanView(),
      },

      home: const AuthGate(),
    );
  }
}
