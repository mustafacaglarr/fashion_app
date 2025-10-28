import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashion_app/app_keys.dart';
import 'package:fashion_app/ui/pages/landing_view.dart';
import 'package:easy_localization/easy_localization.dart'; // i18n

// Çeviri anahtarı yoksa fallback döndür
String _t(String key, String fallback) {
  final v = tr(key);
  return v == key ? fallback : v;
}

class TryonErrorView extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> tips;
  final VoidCallback? onRetry;

  const TryonErrorView({
    super.key,
    this.title = 'Hay aksi! Bir sorun oluştu',
    this.subtitle = 'İşlemi tamamlayamadık. Lütfen tekrar deneyin.',
    this.tips = const [],
    this.onRetry,
  });

  void _goHome() {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // hero icon
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.errorContainer.withOpacity(.9),
                          theme.colorScheme.errorContainer.withOpacity(.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.error.withOpacity(.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.70),
                    ),
                  ),

                  if (tips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tips
                            .map((t) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          t,
                                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 🔽 modern, ikonlu, “pill” butonlar
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onRetry?.call();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          _t('common.retry', 'Try again'),
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        style: _primaryButtonStyle(context),
                      ),
                      // tonal secondary = daha modern görünüm
                      FilledButton.tonalIcon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _goHome();
                        },
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: Text(
                          _t('common.home', 'Home'),
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: _tonalButtonStyle(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== styles =====

ButtonStyle _primaryButtonStyle(BuildContext context) {
  final t = Theme.of(context);
  return FilledButton.styleFrom(
    backgroundColor: t.colorScheme.primary,
    foregroundColor: t.colorScheme.onPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    textStyle: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    shadowColor: t.colorScheme.primary.withOpacity(.25),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.pressed)
            ? t.colorScheme.onPrimary.withOpacity(.10)
            : null),
  );
}

ButtonStyle _tonalButtonStyle(BuildContext context) {
  final t = Theme.of(context);
  return FilledButton.styleFrom(
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    textStyle: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  ).copyWith(
    overlayColor: WidgetStatePropertyAll(
      t.colorScheme.primary.withOpacity(.06),
    ),
  );
}
