// lib/main.dart
import 'package:fashion_app/ui/pages/tryon_wizard_view.dart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ui/theme.dart';
import 'ui/pages/landing_view.dart';
import 'ui/pages/history_view.dart';
import 'ui/pages/profile_view.dart';

import 'ui/viewmodels/tryon_viewmodel.dart';
import 'ui/viewmodels/history_viewmodel.dart';
import 'data/fal_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env opsiyonel: yoksa hata fırlatmasın
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env yoksa sorun değil; --dart-define veya başka yöntemle verilebilir
  }

  // ÖNEM SIRASI: .env(FAL_KEY) -> --dart-define(FAL_KEY) -> boş
  final envKey = dotenv.maybeGet('FAL_KEY') ?? '';
  const defineKey = String.fromEnvironment('FAL_KEY', defaultValue: '');
  final falKey = envKey.isNotEmpty ? envKey : defineKey;

  // Not: Üretimde anahtarı istemciye vermeyin, kendi backend/proxy kullanın.
  final repo = FalDirectRepository(falKey: falKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TryonViewModel(repo)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel()..load()),
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
      theme: buildTheme(), // ui/theme.dart

      // İstersen named route da kullan
      routes: {
        '/tryon': (_) => const TryOnWizardView(),
        '/history': (_) => const HistoryView(),
        '/profile': (_) => const ProfileView(),
      },

      // İlk ekran
      home: const LandingView(),
    );
  }
}
