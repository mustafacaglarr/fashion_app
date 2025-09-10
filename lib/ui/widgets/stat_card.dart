// lib/ui/widgets/stat_card.dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  const StatCard({
    super.key,
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ikonlu rozet
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.black87, size: 22),
          ),
          const SizedBox(height: 10),

          // büyük sayı
          Text(
            number,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),

          // etiket (2 satırı geçmesin, kelime bölme yok)
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true, // kelime bazlı sarar, harf harf bölmez
            style: t.labelMedium?.copyWith(
              color: Colors.black54,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
