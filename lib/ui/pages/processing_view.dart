// lib/ui/pages/processing_view.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'result_view.dart';

class ProcessingView extends StatefulWidget {
  const ProcessingView({super.key});

  @override
  State<ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<ProcessingView> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final vm = context.read<TryonViewModel>();

    // Görseller seçilmemişse nazikçe geri dön
    if (vm.modelPhoto == null || vm.garmentPhoto == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen her iki görseli de seçin.")),
        );
        Navigator.pop(context);
      }
      return;
    }

    await vm.submit();

    if (!mounted) return;

    if (vm.state == TryonState.done) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultView()),
      );
    } else if (vm.state == TryonState.error) {
      // hata varsa geri dön ve mesaj göster
      final msg = vm.errorMessage?.isNotEmpty == true ? vm.errorMessage! : "Bir hata oluştu.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animasyonunu assets’e eklemeyi unutma (pubspec.yaml)
              SizedBox(
                height: 180,
                child: Lottie.asset('assets/processing.json', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text("Görseller işleniyor…", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text("Bu işlem birkaç saniye sürebilir.", style: t.bodyMedium?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
