import 'package:flutter/material.dart';

class FilledButtonLoading extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;
  const FilledButtonLoading({
    super.key,
    required this.loading,
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: FilledButton(
        key: ValueKey(loading),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : child,
      ),
    );
  }
}
