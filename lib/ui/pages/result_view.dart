// lib/ui/pages/result_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fashion_app/ui/viewmodels/tryon_viewmodel.dart';
import 'package:fashion_app/ui/viewmodels/history_viewmodel.dart';
import 'landing_view.dart'; // ana sayfa import

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  bool _bannerVisible = false;
  String _bannerText = "";

  Future<void> _showBanner(String msg) async {
    setState(() {
      _bannerText = msg;
      _bannerVisible = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _bannerVisible = false);
  }

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goHome(context);
        return false; // default pop olmasın
      },
      child: Consumer<TryonViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Sonuç"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goHome(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: vm.reset,
                  tooltip: "Yeni dene",
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  vm.results.isEmpty
                      ? const Center(child: Text("Henüz sonuç yok."))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 24),
                          itemBuilder: (_, i) {
                            final url = vm.results[i].url;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: AspectRatio(
                                    aspectRatio: 864 / 1296,
                                    child: Image.network(url, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    surfaceTintColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 20,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final hist = context.read<HistoryViewModel>();
                                    try {
                                      await hist.saveFromUrl(url);
                                      if (mounted) _showBanner("Geçmişe kaydedildi");
                                    } catch (_) {
                                      if (mounted) _showBanner("Kaydedilemedi");
                                    }
                                  },
                                  icon: const Icon(Icons.download_rounded, color: Colors.black),
                                  label: const Text(
                                    "Kaydet",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                  // Banner
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: AnimatedSlide(
                      offset: _bannerVisible ? Offset.zero : const Offset(0, 0.2),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _bannerVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    _bannerText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
