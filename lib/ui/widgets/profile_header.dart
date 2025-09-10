import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? planLabel;
  final String? avatarPath; // varsa cihazdan görsel kullan

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.planLabel,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFECEEFE),
                backgroundImage: (avatarPath != null) ? AssetImage(avatarPath!) : null,
                child: (avatarPath == null)
                    ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
                    : null,
              ),
              Positioned(
                right: -2, bottom: -2,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6)]),
                  child: const CircleAvatar(
                    radius: 12, backgroundColor: Color(0xFF667EEA),
                    child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // İsim & e-posta & plan
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                if (planLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEEFE), borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(planLabel!, style: t.labelSmall?.copyWith(color: const Color(0xFF667EEA))),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(email, style: t.bodyMedium?.copyWith(color: Colors.black54)),
            ]),
          ),
        ],
      ),
    );
  }
}
