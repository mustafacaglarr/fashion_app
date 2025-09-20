import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('help.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_rounded),
            title: Text(tr('help.contact_us')),
            subtitle: const Text('mustafa.caglar147@gmail.com'),
            onTap: () {
              // Şimdilik boş kalsın (istersen ileride email launch ekleriz)
            },
          ),
        ],
      ),
    );
  }
}
