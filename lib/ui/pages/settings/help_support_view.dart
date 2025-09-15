import 'package:flutter/material.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yardım & Destek')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_rounded),
            title: const Text('Bize Ulaşın'),
            subtitle: const Text('mustafa.caglar147@gmail.com'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
