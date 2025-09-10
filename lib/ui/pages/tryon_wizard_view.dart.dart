import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'package:fashion_app/ui/widgets/filled_button_loading.dart';
import 'package:fashion_app/ui/widgets/image_pick_card.dart';
import 'package:fashion_app/ui/widgets/step_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/tryon_models.dart';
import 'result_view.dart';

class TryOnWizardView extends StatelessWidget {
  const TryOnWizardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TryonViewModel>(
      builder: (context, vm, _) {
        final theme = Theme.of(context);

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
                  child: const Text("Geri"),
                ),
              if (showBack) const SizedBox(width: 12),
              if (showNext)
                FilledButton(
                  onPressed: () => vm.goNext(),
                  child: const Text("İleri"),
                ),
              if (showSubmit)
                FilledButtonLoading(
                  loading: vm.state == TryonState.uploading || vm.state == TryonState.processing,
                  onPressed: vm.canSubmitFromConfirm
                      ? () async {
                          await vm.submit();
                          if (vm.state == TryonState.done && context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultView()));
                          }
                        }
                      : null,
                  child: const Text("Dene"),
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
                    title: "Model Fotoğrafı",
                    subtitle: "Yüz & gövde net, sade arka plan",
                    onTap: vm.pickModelPhoto,
                    path: vm.modelPhoto?.path,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "İpucu: Tek kişi, iyi ışık, sade arka plan en iyi sonucu verir.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(
                    showBack: false,
                    showNext: vm.canNextFromModel,
                    showSubmit: false,
                  ),
                ],
              );

            case TryonStep.garment:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImagePickCard(
                    title: "Kıyafet Görseli",
                    subtitle: "Flat-lay / manken üstünde net çekim",
                    onTap: vm.pickGarmentPhoto,
                    path: vm.garmentPhoto?.path,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "İpucu: Flat-lay ya da net manken fotoğrafı daha iyi sonuç verir.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(
                    showBack: true,
                    showNext: vm.canNextFromGarment,
                    showSubmit: false,
                  ),
                ],
              );

            case TryonStep.confirm:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Özet kartı
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: Text("Kategori", style: theme.textTheme.bodyMedium)),
                          Text(vm.category.name, style: theme.textTheme.titleMedium),
                        ]),
                        const Divider(height: 22),
                        Row(children: [
                          Expanded(child: Text("Mod", style: theme.textTheme.bodyMedium)),
                          Text(vm.mode.name, style: theme.textTheme.titleMedium),
                        ]),
                        const Divider(height: 22),
                        Row(children: [
                          Expanded(child: Text("Kıyafet Foto Tipi", style: theme.textTheme.bodyMedium)),
                          Text(vm.garmentPhotoType, style: theme.textTheme.titleMedium),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Ayarlar (istersen kaldırma; burada değiştirmeye devam edebilirsin)
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<GarmentCategory>(
                        value: vm.category,
                        decoration: const InputDecoration(labelText: "Kategori"),
                        items: GarmentCategory.values
                            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => vm.setCategory(v ?? GarmentCategory.auto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TryonMode>(
                        value: vm.mode,
                        decoration: const InputDecoration(labelText: "Mod"),
                        items: TryonMode.values
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (v) => vm.setMode(v ?? TryonMode.balanced),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: vm.garmentPhotoType,
                    decoration: const InputDecoration(labelText: "Kıyafet Foto Tipi"),
                    items: const [
                      DropdownMenuItem(value: "auto", child: Text("auto")),
                      DropdownMenuItem(value: "model", child: Text("model")),
                      DropdownMenuItem(value: "flat-lay", child: Text("flat-lay")),
                    ],
                    onChanged: (v) => vm.setGarmentPhotoType(v ?? "auto"),
                  ),
                  const SizedBox(height: 20),
                  actionsBar(showBack: true, showNext: false, showSubmit: true),
                ],
              );
          }
        }

        int stepIndex(TryonStep s) => s == TryonStep.model ? 0 : s == TryonStep.garment ? 1 : 2;

        return Scaffold(
          appBar: AppBar(
            title: const Text("VTON — Sanal Deneme"),
            actions: [
              
            ],
          ),
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
