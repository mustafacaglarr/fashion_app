// lib/data/fal_repository.dart
import 'dart:io';
import 'package:fal_client/fal_client.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'tryon_models.dart';

abstract class IFalRepository {
  Future<String> uploadFile(XFile file);       // dönen URL
  Future<TryonResult> runTryOn(TryonRequest req);
}

class FalDirectRepository implements IFalRepository {
  final String falKey;
  late final FalClient _fal;

  FalDirectRepository({required this.falKey}) {
    _fal = FalClient.withCredentials(falKey);
  }

  @override
  Future<String> uploadFile(XFile file) async {
    // fal.storage.upload: dokümana göre XFile kabul eder ve URL döner
    // (Dilerseniz Data URI de gönderebilirsiniz; büyük dosyada performans düşer) :contentReference[oaicite:7]{index=7}
    final url = await _fal.storage.upload(file);
    return url;
  }

  @override
  Future<TryonResult> runTryOn(TryonRequest req) async {
    // Basit kullanım: subscribe => tamamlanana kadar bekler ve sonucu döner
    // (Queue API ile submit/status/result da kullanılabilir) :contentReference[oaicite:8]{index=8}
    final output = await _fal.subscribe("fal-ai/fashn/tryon/v1.6",
        input: req.toFalInputJson(),
        logs: false);

    // Çıktıyı şemaya göre al
    final data = output.data as Map<String, dynamic>?;
    final images = (data?["images"] as List<dynamic>? ?? [])
        .map((e) => TryonResultImage((e as Map<String, dynamic>)["url"] as String))
        .toList();
    return TryonResult(images);
  }
}

/// ÜRETİM: Anahtarı gizlemek için kendi backend'inizi çağırın.
/// POST /tryon { modelUrl, garmentUrl, ... } => { images: [{ url: ...}] }
class FalProxyRepository implements IFalRepository {
  final String baseUrl; // ör: https://your.api/tryon
  FalProxyRepository(this.baseUrl);

  @override
  Future<String> uploadFile(XFile file) async {
    final uri = Uri.parse("$baseUrl/upload");
    final req = http.MultipartRequest("POST", uri);
    req.files.add(await http.MultipartFile.fromPath("file", file.path,
        filename: file.name));
    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // beklenen: {url:"..."}
      final url = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body)?.group(1);
      if (url == null) throw Exception("Upload yanıtı beklenmedik");
      return url;
    }
    throw Exception("Upload hata: ${resp.statusCode}");
  }

  @override
  Future<TryonResult> runTryOn(TryonRequest req) async {
    final uri = Uri.parse("$baseUrl/tryon");
    final resp = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: req.toFalInputJson().toString().replaceAll("'", '"'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final urls = RegExp(r'"url"\s*:\s*"([^"]+)"').allMatches(resp.body)
          .map((m) => m.group(1)!)
          .toList();
      return TryonResult(urls.map((e) => TryonResultImage(e)).toList());
    }
    throw Exception("Try-on hata: ${resp.statusCode}");
  }
}
