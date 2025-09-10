import 'package:fashion_app/ui/pages/landing_view.dart';
import 'package:flutter/material.dart';
import 'ui/theme.dart';

class VtonApp extends StatelessWidget {
  const VtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTON',
      theme: buildTheme(),
      home: const LandingView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
