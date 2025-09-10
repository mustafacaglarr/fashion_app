import 'package:flutter/material.dart';

class LegalView extends StatelessWidget {
  final String title;
  final String content;
  const LegalView({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(content),
      ),
    );
  }
}
