import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacySettingsView extends StatelessWidget {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(text, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        );

    Widget bullet(String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("•  "),
            Expanded(child: Text(text, style: t.bodyMedium)),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr('privacy.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Özet kartı
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('privacy.summary.title'), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(tr('privacy.summary.body'), style: t.bodyMedium?.copyWith(color: Colors.black87)),
              ],
            ),
          ),

          sectionTitle(tr('privacy.sections.processed_data.title')),
          bullet(tr('privacy.sections.processed_data.items.0')),
          bullet(tr('privacy.sections.processed_data.items.1')),
          bullet(tr('privacy.sections.processed_data.items.2')),
          bullet(tr('privacy.sections.processed_data.items.3')),

          sectionTitle(tr('privacy.sections.purposes.title')),
          bullet(tr('privacy.sections.purposes.items.0')),
          bullet(tr('privacy.sections.purposes.items.1')),
          bullet(tr('privacy.sections.purposes.items.2')),
          bullet(tr('privacy.sections.purposes.items.3')),
          bullet(tr('privacy.sections.purposes.items.4')),

          sectionTitle(tr('privacy.sections.legal_basis.title')),
          bullet(tr('privacy.sections.legal_basis.items.0')),
          bullet(tr('privacy.sections.legal_basis.items.1')),
          bullet(tr('privacy.sections.legal_basis.items.2')),
          bullet(tr('privacy.sections.legal_basis.items.3')),

          sectionTitle(tr('privacy.sections.retention.title')),
          bullet(tr('privacy.sections.retention.items.0')),
          bullet(tr('privacy.sections.retention.items.1')),
          bullet(tr('privacy.sections.retention.items.2')),

          sectionTitle(tr('privacy.sections.third_parties.title')),
          bullet(tr('privacy.sections.third_parties.items.0')),
          bullet(tr('privacy.sections.third_parties.items.1')),
          bullet(tr('privacy.sections.third_parties.items.2')),

          sectionTitle(tr('privacy.sections.cross_border.title')),
          bullet(tr('privacy.sections.cross_border.items.0')),

          sectionTitle(tr('privacy.sections.security.title')),
          bullet(tr('privacy.sections.security.items.0')),
          bullet(tr('privacy.sections.security.items.1')),

          sectionTitle(tr('privacy.sections.user_rights.title')),
          bullet(tr('privacy.sections.user_rights.items.0')),
          bullet(tr('privacy.sections.user_rights.items.1')),
          bullet(tr('privacy.sections.user_rights.items.2')),
          bullet(tr('privacy.sections.user_rights.items.3')),
          bullet(tr('privacy.sections.user_rights.items.4')),
          bullet(tr('privacy.sections.user_rights.items.5')),

          sectionTitle(tr('privacy.sections.children.title')),
          bullet(tr('privacy.sections.children.items.0')),

          sectionTitle(tr('privacy.sections.cookies.title')),
          bullet(tr('privacy.sections.cookies.items.0')),

          sectionTitle(tr('privacy.sections.contact.title')),
          bullet(tr('privacy.sections.contact.items.0')),
          bullet(tr('privacy.sections.contact.items.1')),
          bullet(tr('privacy.sections.contact.items.2')),

          sectionTitle(tr('privacy.sections.updates.title')),
          bullet(tr('privacy.sections.updates.items.0')),
        ],
      ),
    );
  }
}
