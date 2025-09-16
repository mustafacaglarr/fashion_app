import 'package:fashion_app/data/plan_models.dart';
import 'package:flutter/material.dart';

class BillingToggle extends StatelessWidget {
  final BillingPeriod value;
  final ValueChanged<BillingPeriod> onChanged;

  const BillingToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final surface = Colors.grey.shade100; // nötr arka plan
    final primary = Colors.teal; // ✅ güven verici yeşil (turuncuyla uyumlu)

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChipButton(
              text: "Aylık",
              selected: value == BillingPeriod.monthly,
              onTap: () => onChanged(BillingPeriod.monthly),
              selectedColor: primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ChipButton(
              text: "Yıllık",
              selected: value == BillingPeriod.yearly,
              onTap: () => onChanged(BillingPeriod.yearly),
              selectedColor: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String text;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ChipButton({
    required this.text,
    this.trailing,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgSel = Colors.white;
    final fg = Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected ? fgSel : fg,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 4),
              Text(
                trailing!,
                style: TextStyle(
                  color: selected ? Colors.white70 : Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
