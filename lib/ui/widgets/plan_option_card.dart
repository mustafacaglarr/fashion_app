import 'package:flutter/material.dart';

class PlanOptionCard extends StatelessWidget {
  final bool selected;
  final Color bgColor;
  final String title;
  final String? tag;         // BEST VALUE, MOST POPULAR
  final Widget features;     // Column(FeatureRow,...)
  final String price;
  final String? strikePrice; // $120 gibi
  final VoidCallback onTap;

  const PlanOptionCard({
    super.key,
    required this.selected,
    required this.bgColor,
    required this.title,
    this.tag,
    required this.features,
    required this.price,
    this.strikePrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFFFFA726) : const Color(0xFFE5E6ED);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol: içerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title, style: titleStyle),
                    const SizedBox(width: 8),
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag!,
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  features,
                ],
              ),
            ),

            // Sağ: fiyat ve ok
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    if (strikePrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        strikePrice!,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.north_east_rounded, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
