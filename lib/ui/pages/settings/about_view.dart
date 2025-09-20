import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    const version = '1.0.0';

    return Scaffold(
      appBar: AppBar(title: Text(tr('about.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(tr('app_title')), // Uygulama adı i18n
            subtitle: Text(tr('about.version', namedArgs: {'version': version})),
          ),
          const SizedBox(height: 8),
          Text(tr('about.description')),
        ],
      ),
    );
  }
}
