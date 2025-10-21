// lib/ui/pages/processing_view.dart
import 'package:fashion_app/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'package:lottie/lottie.dart'; // ✅ Lottie
import 'result_view.dart';

class ProcessingView extends StatefulWidget {
  const ProcessingView({super.key});
  @override
  State<ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<ProcessingView> {
  VoidCallback? _listener;
  late final TryonViewModel _vm;     // VM'i cache'le
  bool _navigated = false;           // tekrar navigasyonu engelle
  late final DateTime _arrivedAt;    // min animasyon süresi için giriş zamanı
  static const Duration _minSplash = Duration(milliseconds: 600);

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  Future<void> _maybeNavigate(TryonState s) async {
    if (!mounted || _navigated) return;

    if (s == TryonState.done || s == TryonState.error) {
      final elapsed = DateTime.now().difference(_arrivedAt);
      if (elapsed < _minSplash) {
        await Future.delayed(_minSplash - elapsed);
      }
      if (!mounted || _navigated) return;

      _navigated = true;
      if (s == TryonState.done) {
        appNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      } else {
        appNavigatorKey.currentState?.maybePop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _arrivedAt = DateTime.now();

    _vm = context.read<TryonViewModel>();

    // State değişimlerini dinle (context kullanmadan)
    _listener = () {
      if (!mounted || _navigated) return;
      _maybeNavigate(_vm.state);
    };
    _vm.addListener(_listener!);

    // İlk frame’de de kontrol et + işi BURADA başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s0 = _vm.state;

      if (s0 == TryonState.idle) {
        _vm.submit(); // await etmiyoruz; listener yönetecek
      } else if (s0 == TryonState.done || s0 == TryonState.error) {
        _maybeNavigate(s0);
      }
      // uploading/processing ise animasyon zaten bu ekranda gösterilecek
    });
  }

  @override
  void dispose() {
    if (_listener != null) {
      try { _vm.removeListener(_listener!); } catch (_) {}
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
              // 🔁 Lottie processing animasyonu
              // assets/processing.json dosyanıza göre yolu kontrol edin
              Lottie.asset(
                'assets/processing.json',
                width: 160,
                height: 160,
                repeat: true,
              ),
              const SizedBox(height: 8),
              Text(
                _trOr('processing.title', 'Processing images...'),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _trOr('processing.subtitle', 'This may take a few seconds.'),
                style: t.bodyMedium?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              if (!isBusy) ...[
                const SizedBox(height: 16),
                Text(
                  _trOr('processing.note_waiting', 'Starting the job...'),
                  style: t.bodySmall?.copyWith(color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
