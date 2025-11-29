// lib/ui/pages/tryon_wizard_view.dart
import 'package:fashion_app/app_keys.dart';
import 'package:fashion_app/ui/pages/processing_view.dart';
import 'package:fashion_app/ui/pages/tryon_limit_view.dart';
import 'package:fashion_app/ui/pages/tryon_error_view.dart';
import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'package:fashion_app/ui/widgets/filled_button_loading.dart';
import 'package:fashion_app/ui/widgets/image_pick_card.dart';
import 'package:fashion_app/ui/widgets/step_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../data/tryon_models.dart';

class TryOnWizardView extends StatefulWidget {
  const TryOnWizardView({super.key});

  static Future<void> open(BuildContext context) async {
    context.read<TryonViewModel>().reset();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TryOnWizardView()),
    );
  }

  @override
  State<TryOnWizardView> createState() => _TryOnWizardViewState();
}

class _TryOnWizardViewState extends State<TryOnWizardView> {
  bool _submitting = false;
  bool _errorPushed = false;

  // ---- Yeni: destekli uzantı kontrolü
  static const _okExts = {'jpg', 'jpeg', 'png'};
  bool _isSupportedPath(String? path) {
    if (path == null || path.isEmpty) return true; // henüz seçilmemişse engelleme
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return false;
    final ext = path.substring(dot + 1).toLowerCase();
    return _okExts.contains(ext);
  }

  // ---- Yeni: modern uyarı sayfası (bottom sheet)
  Future<void> _showUnsupportedSheet({
    required bool forModel, // true: model foto, false: kıyafet
    required TryonViewModel vm,
  }) async {
    final theme = Theme.of(context);
    final title = _trOr('tryon.unsupported.title', 'Bu fotoğraf türü desteklenmiyor');
    final desc  = _trOr(
      'tryon.unsupported.desc',
      'Lütfen PNG ya da JPG/JPEG formatında bir fotoğraf seçin. WEBP/HEIC şu anda desteklenmeyebilir.',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16 + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer, size: 32),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(desc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.75),
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_trOr('common.close', 'Kapat')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      // yeniden seçim
                      if (forModel) {
                        await vm.pickModelPhoto();
                      } else {
                        await vm.pickGarmentPhoto();
                      }
                      if (mounted) Navigator.pop(context);
                      // seçilen yenisi de uygunsuzsa kullanıcı tekrar uyarılacak
                      final path = forModel ? vm.modelPhoto?.path : vm.garmentPhoto?.path;
                      if (path != null && !_isSupportedPath(path)) {
                        // VM’e dokunmadan yalnızca uyarı veriyoruz
                        if (mounted) {
                          await _showUnsupportedSheet(forModel: forModel, vm: vm);
                        }
                      }
                      setState(() {}); // görüntüyü tazele
                    },
                    child: Text(_trOr('tryon.unsupported.pick_again', 'Başka fotoğraf seç')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<TryonViewModel>().reset();
    });
  }

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  // ---------- (mevcut hata -> ErrorView yönlendirme) ----------
  List<String> _buildUserTips(String? err) {
    final tips = <String>[];
    final s = (err ?? '').toLowerCase();
    final isNetwork = s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network') ||
        (s.contains('http') && s.contains('timeout'));
    final isInvalidImage = s.contains('invalid image') ||
        s.contains('expecting a valid url or base64') ||
        s.contains('unsupported') ||
        s.contains('webp') ||
        s.contains('heic') ||
        s.contains('image data');

    if (isNetwork) {
      tips.addAll([
        _trOr('tryon.error.tips.network.0', 'İnternet bağlantınızı kontrol edin (Wi-Fi/Veri).'),
        _trOr('tryon.error.tips.network.1', 'VPN/Proxy kullanıyorsanız kapatıp tekrar deneyin.'),
      ]);
    }
    if (isInvalidImage) {
      tips.addAll([
        _trOr('tryon.error.tips.format.0', 'PNG veya JPEG formatı kullanın (WEBP/HEIC desteklenmeyebilir).'),
        _trOr('tryon.error.tips.format.1', 'Fotoğraf çok büyükse daha küçük bir kopyasını deneyin.'),
      ]);
    }
    if (tips.isEmpty) {
      tips.addAll([
        _trOr('tryon.error.tips.generic.0', 'İnternetinizi kontrol edip tekrar deneyin.'),
        _trOr('tryon.error.tips.generic.1', 'PNG/JPEG formatında bir fotoğraf seçin.'),
      ]);
    }
    return tips;
  }

  void _maybeOpenError(TryonViewModel vm) {
    if (_errorPushed || vm.state != TryonState.error) return;
    _errorPushed = true;
    if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
      // ignore: avoid_print
      print('TryOn error: ${vm.errorMessage}');
    }
    final tips = _buildUserTips(vm.errorMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TryonErrorView(
            title: _trOr('tryon.error.title', 'Hay aksi! Bir sorun oluştu'),
            subtitle: _trOr('tryon.error.subtitle',
                'İşlemi tamamlayamadık. Lütfen tekrar deneyin.'),
            tips: tips,
            onRetry: () {
              vm.errorMessage = null;
              vm.state = TryonState.idle;
              vm.notifyListeners();
              appNavigatorKey.currentState?.maybePop();
              _errorPushed = false;
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TryonViewModel>(
      builder: (context, vm, _) {
        final theme = Theme.of(context);

        _maybeOpenError(vm);

        String catLabel(GarmentCategory c) => _trOr('tryon.category.${c.name}', c.name);
        String modeLabel(TryonMode m) => _trOr('tryon.mode.${m.name}', m.name);
        String photoTypeLabel(String v) => _trOr('tryon.photoType.$v', v);

        Future<void> _handleTry() async {
          if (!vm.canSubmitFromConfirm || _submitting) return;
          setState(() => _submitting = true);

          final qr = await vm.checkQuotaOnly();
          if (!qr.allowed) {
            setState(() => _submitting = false);
            final isFree = qr.plan == 'free';
            final title = isFree
                ? _trOr('tryon.quota.errors.title_free', 'Günlük hakkın doldu')
                : _trOr('tryon.quota.errors.title_paid', 'Plan limitin doldu');

            final msgKey = switch (qr.code) {
              'free_daily_exceeded'   => 'tryon.quota.errors.free_daily_exceeded',
              'paid_monthly_exceeded' => 'tryon.quota.errors.paid_monthly_exceeded',
              'no_session'            => 'tryon.quota.errors.no_session',
              _                       => 'tryon.quota.errors.generic',
            };

            final subtitle = _trOr(
              msgKey,
              isFree
                  ? 'Daha fazla deneme için Süper’e geçebilirsin.'
                  : 'Limitini artırmak için planını yönet.',
            );

            final primaryCta = isFree
                ? _trOr('tryon.quota.cta_upgrade', '₺0,00 ÖDEYEREK DENE')
                : _trOr('tryon.quota.cta_manage', 'PLANI YÖNET');

            final secondaryCta = _trOr('common.no_thanks', 'HAYIR TEŞEKKÜRLER');

            const defaults = <String>[
              '100 results/month',
              'HD resolution',
              'Lighting/skin tone matching (color match)',
              'Pose normalization (alignment)',
              'No watermark · Fast queue',
              'No ads',
            ];
            final proBullets = List<String>.generate(
              defaults.length, (i) => _trOr('plans.pro.bullets.$i', defaults[i]),
            );

            final features = <FeatureItem>[
              FeatureItem.infinityIcon(proBullets[0], ''),
              FeatureItem.refresh(proBullets[1], ''),
              FeatureItem.refresh(proBullets[2], ''),
              FeatureItem.headphones(proBullets[3], ''),
              FeatureItem.infinityIcon(proBullets[4], ''),
              FeatureItem.adFree(proBullets[5], ''),
            ];

            appNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => TryonLimitView(
                  badgeText: 'PREMIUM',
                  title: title,
                  subtitle: subtitle,
                  lottieAsset: 'assets/error.json',
                  features: features,
                  primaryCtaText: primaryCta,
                  onPrimary: () => appNavigatorKey.currentState?.pushReplacementNamed('/upgrade'),
                  secondaryCtaText: secondaryCta,
                  onSecondary: () => appNavigatorKey.currentState?.maybePop(),
                ),
              ),
            );
            return;
          }

          if (mounted) {
            setState(() => _submitting = false);
            appNavigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const ProcessingView()),
            );
          }
        }

        Widget _inlineInvalidHint() {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _trOr('tryon.unsupported.inline',
                        'Bu fotoğraf türü desteklenmiyor. PNG veya JPG seçin.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget actionsBar({
          required bool showBack,
          required bool showNext,
          required bool showSubmit,
        }) {
          return Row(
            children: [
              if (showBack)
                OutlinedButton(
                  onPressed: vm.goBack,
                  child: Text(tr('tryon.actions.back')),
                ),
              if (showBack) const SizedBox(width: 12),
              if (showNext)
                FilledButton(
                  onPressed: showNext ? vm.goNext : null,
                  child: Text(tr('tryon.actions.next')),
                ),
              if (showSubmit)
                FilledButtonLoading(
                  loading: _submitting,
                  onPressed: vm.canSubmitFromConfirm ? _handleTry : null,
                  child: Text(tr('tryon.actions.try')),
                ),
            ],
          );
        }

        Widget stepBody() {
          switch (vm.step) {
            case TryonStep.model: {
              final invalid = !_isSupportedPath(vm.modelPhoto?.path);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImagePickCard(
                    title: tr('tryon.model.title'),
                    subtitle: tr('tryon.model.subtitle'),
                    onTap: () async {
                      await vm.pickModelPhoto();
                      final p = vm.modelPhoto?.path;
                      if (p != null && !_isSupportedPath(p)) {
                        await _showUnsupportedSheet(forModel: true, vm: vm);
                      }
                      setState(() {}); // kartı tazele
                    },
                    path: vm.modelPhoto?.path,
                  ),
                  if (invalid) _inlineInvalidHint(),
                  const SizedBox(height: 16),
                  Text(
                    tr('tryon.model.tip'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(
                    showBack: false,
                    showNext: vm.canNextFromModel && !invalid, // ❗ geçişi engelle
                    showSubmit: false,
                  ),
                ],
              );
            }

            case TryonStep.garment: {
              final invalid = !_isSupportedPath(vm.garmentPhoto?.path);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImagePickCard(
                    title: tr('tryon.garment.title'),
                    subtitle: tr('tryon.garment.subtitle'),
                    onTap: () async {
                      await vm.pickGarmentPhoto();
                      final p = vm.garmentPhoto?.path;
                      if (p != null && !_isSupportedPath(p)) {
                        await _showUnsupportedSheet(forModel: false, vm: vm);
                      }
                      setState(() {});
                    },
                    path: vm.garmentPhoto?.path,
                  ),
                  if (invalid) _inlineInvalidHint(),
                  const SizedBox(height: 16),
                  Text(
                    tr('tryon.garment.tip'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(
                    showBack: true,
                    showNext: vm.canNextFromGarment && !invalid, // ❗ geçişi engelle
                    showSubmit: false,
                  ),
                ],
              );
            }

            case TryonStep.confirm:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: Text(tr('tryon.confirm.summary.category'), style: theme.textTheme.bodyMedium)),
                          Text(catLabel(vm.category), style: theme.textTheme.titleMedium),
                        ]),
                        const Divider(height: 22),
                        Row(children: [
                          Expanded(child: Text(tr('tryon.confirm.summary.mode'), style: theme.textTheme.bodyMedium)),
                          Text(modeLabel(vm.mode), style: theme.textTheme.titleMedium),
                        ]),
                        const Divider(height: 22),
                        Row(children: [
                          Expanded(child: Text(tr('tryon.confirm.summary.photo_type'), style: theme.textTheme.bodyMedium)),
                          Text(photoTypeLabel(vm.garmentPhotoType), style: theme.textTheme.titleMedium),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<GarmentCategory>(
                        value: vm.category,
                        decoration: InputDecoration(labelText: tr('tryon.confirm.summary.category')),
                        items: GarmentCategory.values
                            .map((c) => DropdownMenuItem(value: c, child: Text(catLabel(c))))
                            .toList(),
                        onChanged: (v) => vm.setCategory(v ?? GarmentCategory.auto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TryonMode>(
                        value: vm.mode,
                        decoration: InputDecoration(labelText: tr('tryon.confirm.summary.mode')),
                        items: TryonMode.values
                            .map((m) => DropdownMenuItem(value: m, child: Text(modeLabel(m))))
                            .toList(),
                        onChanged: (v) => vm.setMode(v ?? TryonMode.balanced),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: vm.garmentPhotoType,
                    decoration: InputDecoration(labelText: tr('tryon.confirm.summary.photo_type')),
                    items: const ['auto', 'model', 'flat-lay']
                        .map((v) => DropdownMenuItem(value: v, child: Text(photoTypeLabel(v))))
                        .toList(),
                    onChanged: (v) => vm.setGarmentPhotoType(v ?? 'auto'),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(showBack: true, showNext: false, showSubmit: true),
                ],
              );
          }
        }

        int stepIndex(TryonStep s) => s == TryonStep.model ? 0 : s == TryonStep.garment ? 1 : 2;

        return Scaffold(
          appBar: AppBar(title: Text(tr('tryon.appbar_title'))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                StepHeader(currentIndex: stepIndex(vm.step)),
                const SizedBox(height: 12),
                stepBody(),
              ],
            ),
          ),
        );
      },
    );
  }
}
