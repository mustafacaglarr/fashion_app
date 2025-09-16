import 'package:fashion_app/data/plan_models.dart';
import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final PlanTier tier;
  final String title;
  final String description;
  final List<String> bullets;
  final String price;
  final String? compareAt;
  final String? trial;
  final String? monthlyEq;
  final String? finePrint;
  final bool selected;
  final bool highlight; // Pro için true olacak
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.tier,
    required this.title,
    required this.description,
    required this.bullets,
    required this.price,
    this.compareAt,
    this.trial,
    this.monthlyEq,
    this.finePrint,
    required this.selected,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 🔥 highlight == true ise turuncu yapıyoruz
    final bg = highlight ? Colors.orange.shade100 : Colors.white;
    final border = selected ? Colors.orange : Colors.black12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                if (trial != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trial!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.black54)),

            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b)),
                    ],
                  ),
                )),

            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                if (compareAt != null)
                  Text(
                    compareAt!,
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45),
                  ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: selected ? Colors.deepOrange : Colors.black38),
              ],
            ),
            if (monthlyEq != null) ...[
              const SizedBox(height: 4),
              Text(
                monthlyEq!,
                style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            if (finePrint != null) ...[
              const SizedBox(height: 6),
              Text(finePrint!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
