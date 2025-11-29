import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/history_item.dart';
import '../viewmodels/history_viewmodel.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    // sayfa ilk açıldığında bir kez yükle
    // (Provider hazır olduğunda çağırmak için microtask)
    Future.microtask(() {
      if (!_loadedOnce && mounted) {
        context.read<HistoryViewModel>().load();
        _loadedOnce = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(builder: (context, vm, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('history.title')),
          actions: [
            if (vm.items.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: tr('history.clear_all'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(tr('history.dialog.clear_title')),
                      content: Text(tr('history.dialog.clear_content')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('common.cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr('history.clear')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await vm.clearAll();
                },
              ),
          ],
        ),
        body: switch (vm.state) {
          HistoryState.loading => const Center(child: CircularProgressIndicator()),
          HistoryState.error => Center(child: Text(vm.error ?? tr('errors.generic'))),
          _ => vm.items.isEmpty
              ? Center(child: Text(tr('history.empty')))
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: vm.items.length,
                      itemBuilder: (_, i) =>
                          _HistoryTile(item: vm.items[i], onDelete: () => vm.remove(i)),
                    ),
                  ),
                ),
        },
      );
    });
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onDelete;
  const _HistoryTile({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final f = File(item.path);
    return GestureDetector(
      onTap: () {
        if (f.existsSync()) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.black,
              child: InteractiveViewer(
                child: Image.file(f, fit: BoxFit.contain),
              ),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (f.existsSync())
              Image.file(f, fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFFF0F1F6),
                alignment: Alignment.center,
                child: const Icon(Icons.image),
              ),
            Positioned(
              right: 6,
              top: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                  onPressed: onDelete,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
