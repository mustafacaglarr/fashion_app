import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onChanged;

  const SettingTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  })  : isSwitch = false,
        switchValue = false,
        onChanged = null;

  const SettingTile.switcher({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required bool value,
    required this.onChanged,
  })  : trailing = null,
        onTap = null,
        isSwitch = true,
        switchValue = value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFF0F1F6),
          child: Icon(leading, color: Colors.black87),
        ),
        title: Text(
          title,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: (subtitle != null)
            ? Text(
                subtitle!,
                style: t.bodySmall?.copyWith(color: Colors.black54),
              )
            : null,
        trailing: isSwitch
            ? Switch(
                value: switchValue,
                onChanged: onChanged,
                activeColor: const Color.fromARGB(255, 18, 83, 137),            // aktif top
                activeTrackColor: Colors.blue[200],  // aktif track
                inactiveThumbColor: Colors.grey,     // pasif top gri
                inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),// pasif track açık gri
              )
            : (trailing ?? const Icon(Icons.chevron_right_rounded)),
      ),
    );
  }
}
