import 'package:fashion_app/app_keys.dart';
import 'package:fashion_app/ui/pages/processing_view.dart';
import 'package:fashion_app/ui/pages/settings/plan_view.dart';
import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'package:fashion_app/ui/widgets/filled_button_loading.dart';
import 'package:fashion_app/ui/widgets/image_pick_card.dart';
import 'package:fashion_app/ui/widgets/step_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // ⬅️ i18n
import '../../../data/tryon_models.dart';

class TryOnWizardView extends StatefulWidget {
  const TryOnWizardView({super.key});

  /// İstersen hep bunu çağır: yeni route + anında reset.
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<TryonViewModel>().reset();
    });
  }

  // ⬇️ Eksik çeviri durumunda enum adı/ham değerle geri dön.
  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TryonViewModel>(
      builder: (context, vm, _) {
        final theme = Theme.of(context);

        String catLabel(GarmentCategory c) => _trOr('tryon.category.${c.name}', c.name);
        String modeLabel(TryonMode m) => _trOr('tryon.mode.${m.name}', m.name);
        String photoTypeLabel(String v) => _trOr('tryon.photoType.$v', v);

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
                  onPressed: vm.goNext,
                  child: Text(tr('tryon.actions.next')),
                ),
              if (showSubmit)
                // TryOnWizardView -> actionsBar(showSubmit: true) bölümünde
                FilledButtonLoading(
                  loading: vm.state == TryonState.uploading || vm.state == TryonState.processing,
                  // actionsBar içindeki onPressed
onPressed: vm.canSubmitFromConfirm ? () async {
  final qr = await vm.submitWithQuota(); // ⬅️ context parametresi yok

  if (qr != null && !qr.allowed) {
    final msgKey = switch (qr.code) {
      'free_daily_exceeded'   => 'tryon.quota.errors.free_daily_exceeded',
      'paid_monthly_exceeded' => 'tryon.quota.errors.paid_monthly_exceeded',
      'no_session'            => 'tryon.quota.errors.no_session',
      _                       => 'tryon.quota.errors.generic',
    };
    rootMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(tr(msgKey))));

    if (qr.plan == 'free') {
      appNavigatorKey.currentState?.pushNamed('/profile'); // veya plan ekranınız
    }
    return;
  }

  // izin verildiyse ProcessingView’a geç
  appNavigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => const ProcessingView()),
  );
} : null,



                  child: Text(tr('tryon.actions.try')),
                ),

            ],
          );
        }

        Widget stepBody() {
          switch (vm.step) {
            case TryonStep.model:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImagePickCard(
                    title: tr('tryon.model.title'),
                    subtitle: tr('tryon.model.subtitle'),
                    onTap: vm.pickModelPhoto,
                    path: vm.modelPhoto?.path,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('tryon.model.tip'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(showBack: false, showNext: vm.canNextFromModel, showSubmit: false),
                ],
              );

            case TryonStep.garment:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImagePickCard(
                    title: tr('tryon.garment.title'),
                    subtitle: tr('tryon.garment.subtitle'),
                    onTap: vm.pickGarmentPhoto,
                    path: vm.garmentPhoto?.path,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('tryon.garment.tip'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(showBack: true, showNext: vm.canNextFromGarment, showSubmit: false),
                ],
              );

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
                if (vm.state == TryonState.error && (vm.errorMessage?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 8),
                  Text(vm.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
