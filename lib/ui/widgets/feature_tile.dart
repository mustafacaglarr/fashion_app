import 'package:flutter/material.dart';

class FeatureTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color start, end;
  const FeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22)),
        const Spacer(),
        Text(title, style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: t.bodySmall?.copyWith(color: Colors.white70)),
      ]),
    );
  }
}
