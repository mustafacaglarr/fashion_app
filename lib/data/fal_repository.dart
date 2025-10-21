// lib/data/fal_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;

import 'tryon_models.dart';

abstract class IFalRepository {
  Future<String> uploadFile(XFile file); // Data URI
  Future<TryonResult> runTryOn(TryonRequest req);
}

class FalFunctionsRepository implements IFalRepository {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<String> uploadFile(XFile x) async {
    final file = File(x.path);
    if (!await file.exists()) {
      throw Exception('File not found: ${x.path}');
    }
    final bytes = await file.readAsBytes();

    final ext = p.extension(x.path).toLowerCase();
    final mime = (ext == '.png')
        ? 'image/png'
        : (ext == '.jpg' || ext == '.jpeg')
            ? 'image/jpeg'
            : 'application/octet-stream';

    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

// lib/data/fal_repository.dart
@override
Future<TryonResult> runTryOn(TryonRequest req) async {
  final callable = _functions.httpsCallable('tryOn');

  // 🔒 Gizlilik: tüm alanları FAL şemasındaki "input" olarak ilet
  final resp = await callable.call({
    'input': req.toFalInputJson(),
  });

  final map = (resp.data as Map?) ?? const {};
  final list = (map['images'] as List?) ?? const [];

  if (list.isEmpty) {
    throw FirebaseFunctionsException(
      code: 'unavailable',
      message: 'Provider returned no images (normalized empty)',
      details: map,
    );
  }

  final out = list.map((e) {
    final url = (e is Map) ? (e['url'] ?? e['image'] ?? '') : e.toString();
    return TryonResultImage(url.toString());
  }).toList();

  return TryonResult(out);
}

}
