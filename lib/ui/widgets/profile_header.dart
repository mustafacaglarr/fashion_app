// lib/ui/widgets/profile_header.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fashion_app/services/local_avatar_service.dart';

class ProfileHeader extends StatefulWidget {
  final String name;
  final String email;
  final String? planLabel;
  final String? localAvatarPath;
  final ValueChanged<String>? onAvatarChanged;
  final String userId;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.planLabel,
    this.localAvatarPath,
    this.onAvatarChanged,
    this.userId = 'local',
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _busy = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.localAvatarPath;
  }

  Future<void> _pick() async {
    try {
      setState(() => _busy = true);
      final savedPath = await LocalAvatarService.pickAndSave(userId: widget.userId);
      if (savedPath != null) {
        setState(() => _path = savedPath);
        widget.onAvatarChanged?.call(savedPath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seçilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasImage = _path != null && _path!.isNotEmpty && File(_path!).existsSync();

    Widget avatar() {
      if (!hasImage) {
        return const CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFECEEFE),
          child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
        );
      }
      // Cache’i zorlamak için anahtar veriyoruz
      return ClipOval(
        child: SizedBox(
          width: 64, height: 64,
          child: Image.file(
            File(_path!),
            key: ValueKey(_path), // ← path değişince widget kesin yeniden çizilir
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              avatar(),
              Positioned(
                right: -2, bottom: -2,
                child: _busy
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : InkWell(
                        onTap: _pick,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6)],
                          ),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF667EEA),
                            child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(widget.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (widget.planLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFECEEFE), borderRadius: BorderRadius.circular(999)),
                    child: Text(widget.planLabel!, style: t.labelSmall?.copyWith(color: const Color(0xFF667EEA))),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(widget.email, style: t.bodyMedium?.copyWith(color: Colors.black54)),
            ]),
          ),
        ],
      ),
    );
  }
}
