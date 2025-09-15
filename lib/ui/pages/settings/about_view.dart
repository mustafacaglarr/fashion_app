import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Fashion App'),
            subtitle: Text('Sürüm: 1.0.0'),
          ),
          SizedBox(height: 8),
          Text('Bu uygulama, sanal kıyafet denemeyi AI ile kolaylaştırır.'),
        ],
      ),
    );
  }
}
