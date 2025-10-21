import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TryonLimitView extends StatelessWidget {
  final String title;
  final String subtitle;

  final String primaryCtaText;
  final VoidCallback onPrimary;

  final String secondaryCtaText;
  final VoidCallback onSecondary;

  final List<FeatureItem> features;
  final String badgeText;

  final String? lottieAsset; // varsa öncelikli
  final String? mascotAsset; // yoksa fallback

  const TryonLimitView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryCtaText,
    required this.onPrimary,
    required this.secondaryCtaText,
    required this.onSecondary,
    required this.features,
    this.badgeText = 'SUPER',
    this.lottieAsset,
    this.mascotAsset,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF5BD),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          final isSmall = h < 680;
          final isTall  = h > 820;

          final double animH = isSmall ? 140 : (isTall ? 300 : 220);
          final double circle = (w * .9).clamp(280.0, 560.0).toDouble();

          return Stack(
            children: [
              // Dekoratif daire (arka plan)
              Positioned(
                top: h * 0.08,
                left: (w - circle) / 2,
                child: Container(
                  width: circle,
                  height: circle,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF1A6),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Üst rozet
                      Row(children: [
                        const Spacer(),
                        _Badge(text: badgeText),
                      ]),
                      const SizedBox(height: 8),

                      // Başlıklar
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: t.titleLarge?.copyWith(
                          color: const Color(0xFF3D3D3D),
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(
                            color: const Color(0xFF5A5A5A),
                            letterSpacing: .3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Animasyon (sabit, scroll yok)
                      SizedBox(
                        height: animH,
                        child: Center(
                          child: _Visual(
                            lottieAsset: lottieAsset,
                            imageAsset: mascotAsset,
                            height: animH,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ALT BEYAZ PANEL (sabit yükseklikte; içinde scroll yok)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: _BottomPanel(
                                features: features,
                                primaryCtaText: primaryCtaText,
                                onPrimary: onPrimary,
                                secondaryCtaText: secondaryCtaText,
                                onSecondary: onSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ---------- Alt panel: Özellikler + CTA'lar (tamamen scrollsuz) ----------- */

class _BottomPanel extends StatelessWidget {
  final List<FeatureItem> features;
  final String primaryCtaText;
  final VoidCallback onPrimary;
  final String secondaryCtaText;
  final VoidCallback onSecondary;

  const _BottomPanel({
    required this.features,
    required this.primaryCtaText,
    required this.onPrimary,
    required this.secondaryCtaText,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Altta CTA alanlarını sabitliyoruz ki her zaman görünür kalsın.
      const double primaryBtnH = 50;
      const double secondaryH  = 36; // TextButton yaklaşık
      const double gaps        = 10 + 6; // aradaki boşluklar
      final   double reserved  = primaryBtnH + secondaryH + gaps;

      final double featuresArea = (c.maxHeight - reserved).clamp(0, c.maxHeight);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Özellikler: eldeki yüksekliğe sığacak kadarını 2 sütunlu grid gibi çiz
          SizedBox(
            height: featuresArea,
            child: _FeaturesNoScroll(items: features),
          ),

          const SizedBox(height: 10),

          // Primary CTA (turuncu) — sabit yükseklik
          SizedBox(
            height: primaryBtnH,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                primaryCtaText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Secondary CTA — her zaman panelin en altında
          SizedBox(
            height: secondaryH,
            child: TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryCtaText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE07000),
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/* ----------- Özellikler: tamamen scrollsuz 2 sütun yerleşim ---------------- */

class _FeaturesNoScroll extends StatelessWidget {
  final List<FeatureItem> items;
  const _FeaturesNoScroll({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Her “karo” için hedef yükseklik ve sütun sayısı
      const double tileH = 60;
      const int columns = 2;
      const double vGap = 10;
      const double hGap = 10;

      // Kaç satır sığar?
      final rows = ((c.maxHeight + vGap) / (tileH + vGap)).floor().clamp(0, 1000);
      final slots = (rows * columns).clamp(0, items.length);
      final visible = items.take(slots).toList();

      // Scroll kullanmadan, satır-satır elle çiz
      List<Widget> buildRow(int start) {
        final left  = start < visible.length ? visible[start] : null;
        final right = start + 1 < visible.length ? visible[start + 1] : null;
        return [
          Expanded(child: left  != null ? _FeatureTile(item: left)  : const SizedBox()),
          const SizedBox(width: hGap),
          Expanded(child: right != null ? _FeatureTile(item: right) : const SizedBox()),
        ];
      }

      final rowsWidgets = <Widget>[];
      for (int i = 0; i < visible.length; i += 2) {
        rowsWidgets.add(SizedBox(
          height: tileH,
          child: Row(children: buildRow(i)),
        ));
        if (i + 2 < visible.length) rowsWidgets.add(const SizedBox(height: vGap));
      }

      return Column(children: rowsWidgets);
    });
  }
}

/* -------------------------- Küçük bileşenler ------------------------------ */

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC34D), Color(0xFFFF8A00)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

/// Lottie > Image > Emoji sırasıyla görsel
class _Visual extends StatelessWidget {
  final String? lottieAsset;
  final String? imageAsset;
  final double height;
  const _Visual({this.lottieAsset, this.imageAsset, required this.height});

  @override
  Widget build(BuildContext context) {
    if (lottieAsset != null && lottieAsset!.isNotEmpty) {
      return Lottie.asset(
        lottieAsset!,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
      );
    }
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(imageAsset!, height: height - 20, fit: BoxFit.contain);
    }
    return Container(
      height: height - 40,
      width: height - 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFC34D), Color(0xFFFF8A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Text('🙂', style: TextStyle(fontSize: 54, color: Colors.white)),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final FeatureItem item;
  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: item.gradientColors),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: t.bodySmall?.copyWith(color: const Color(0xFF3D3D3D), height: 1.2),
                children: [
                  TextSpan(
                    text: '${item.bold} ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text: item.rest,
                    style: const TextStyle(color: Color(0xFF5A5A5A)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Özellik satırı model (sıcak palet)
class FeatureItem {
  final String bold;
  final String rest;
  final List<Color> gradientColors;
  const FeatureItem(this.bold, this.rest, this.gradientColors);

  factory FeatureItem.headphones(String bold, String rest) =>
      FeatureItem(bold, rest, const [Color(0xFFFFC34D), Color(0xFFFF9B27)]);
  factory FeatureItem.refresh(String bold, String rest) =>
      FeatureItem(bold, rest, const [Color(0xFFFFD580), Color(0xFFFF8A00)]);
  factory FeatureItem.infinityIcon(String bold, String rest) =>
      FeatureItem(bold, rest, const [Color(0xFFFFB74D), Color(0xFFFF8A00)]);
  factory FeatureItem.adFree(String bold, String rest) =>
      FeatureItem(bold, rest, const [Color(0xFFFFE29A), Color(0xFFFFB347)]);
}
