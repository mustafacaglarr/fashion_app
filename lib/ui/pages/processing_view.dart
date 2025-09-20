// lib/ui/pages/processing_view.dart
import 'package:fashion_app/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'result_view.dart';

// ⬇️ appNavigatorKey, rootMessengerKey import et
import '../../main.dart'; // veya keys’i koyduğun dosya

class ProcessingView extends StatefulWidget {
  const ProcessingView({super.key});
  @override
  State<ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<ProcessingView> {
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TryonViewModel>();

      _listener = () {
        // UI aksiyonlarını post-frame'e sar — build sırasında tetiklenmesin
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (vm.state == TryonState.error) {
            final msg = (vm.errorMessage?.isNotEmpty ?? false)
                ? vm.errorMessage!
                : tr('processing.generic_error');

            // ⬇️ context YOK — global messenger kullan
            rootMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text(msg)),
            );

            // ⬇️ context YOK — global navigator kullan
            appNavigatorKey.currentState?.maybePop();
          } else if (vm.state == TryonState.done) {
            appNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultView()),
            );
          }
        });
      };

      vm.addListener(_listener!);

      // Eğer zaten DONE ise hemen sonuç ekranına geç
      if (vm.state == TryonState.done) {
        appNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      }
    });
  }

  @override
  void dispose() {
    // ⬇️ context.read() KULLANMA — dispose’da context’e dokunma
    if (_listener != null) {
      // provider’a erişirken context kullanmamak için listen:false ile mounted check’ine gerek yok
      try {
        final vm = Provider.of<TryonViewModel>(context, listen: false);
        vm.removeListener(_listener!);
      } catch (_) {/* widget dispose iken erişemezsek sessiz geç */}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vm = context.watch<TryonViewModel>();
    final isBusy = vm.state == TryonState.uploading || vm.state == TryonState.processing;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 180, child: Lottie.asset('assets/processing.json')),
              const SizedBox(height: 16),
              Text(tr('processing.title'), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(tr('processing.subtitle'), style: t.bodyMedium?.copyWith(color: Colors.black54), textAlign: TextAlign.center),
              if (!isBusy) ...[
                const SizedBox(height: 16),
                Text(tr('processing.note_waiting'), style: t.bodySmall?.copyWith(color: Colors.black45), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
