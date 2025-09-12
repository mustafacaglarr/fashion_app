import 'package:flutter/material.dart';

class StepHeader extends StatelessWidget {
  final int currentIndex; // 0,1,2
  const StepHeader({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = const ["Model", "Kıyafet", "Onay"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i <= currentIndex;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active
                      ? const Color.fromARGB(255, 0, 38, 255)
                      : const Color(0xFFE1E3EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) => Text(
            titles[i],
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
              color: i == currentIndex ? theme.colorScheme.primary : Colors.black54,
            ),
          )),
        ),
      ],
    );
  }
}
