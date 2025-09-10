import 'package:flutter/material.dart';
import '../style/app_colors.dart';

class CtaBanner extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onTap;
  const CtaBanner({super.key, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.g1, AppColors.g2]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: t.bodyMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 12),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3F3D56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: onTap,
          child: const Text("Başlayalım"),
        ),
      ]),
    );
  }
}
