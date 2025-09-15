import 'package:flutter/material.dart';

class FeatureRow extends StatelessWidget {
  final String text;
  final bool limited;
  const FeatureRow({super.key, required this.text, this.limited = false});

  @override
  Widget build(BuildContext context) {
    final color = limited ? Colors.orange : Colors.green;
    final icon = limited ? Icons.info_outline : Icons.check_circle_rounded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
