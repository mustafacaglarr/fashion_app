import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // tr() kullandığımız için const kaldırıldı
      children: [
        _StepRow(
          step: 1,
          title: tr('home.howitworks.step1.title'),
          subtitle: tr('home.howitworks.step1.subtitle'),
          icon: Icons.photo_camera_back_rounded,
          color: const Color(0xFF667EEA),
        ),
        const _StepDivider(),
        _StepRow(
          step: 2,
          title: tr('home.howitworks.step2.title'),
          subtitle: tr('home.howitworks.step2.subtitle'),
          icon: Icons.checkroom_rounded,
          color: const Color(0xFF10B981),
        ),
        const _StepDivider(),
        _StepRow(
          step: 3,
          title: tr('home.howitworks.step3.title'),
          subtitle: tr('home.howitworks.step3.subtitle'),
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int step;
  final String title, subtitle;
  final IconData icon;
  final Color color;

  const _StepRow({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text("$step", style: const TextStyle(color: Colors.white)),
            ),
            if (step != 3)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE2E5EE),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              Text(subtitle, style: t.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 8);
}
