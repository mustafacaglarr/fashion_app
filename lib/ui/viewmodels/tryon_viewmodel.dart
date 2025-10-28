// lib/viewmodels/tryon_viewmodel.dart
import 'dart:io';
import 'package:fashion_app/data/fal_repository.dart';
import 'package:fashion_app/data/tryon_models.dart';
import 'package:fashion_app/services/tryon_quota_service_firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum TryonState { idle, picking, uploading, processing, done, error }
enum TryonStep { model, garment, confirm }
class TryonViewModel extends ChangeNotifier {
  final IFalRepository repo;

  TryonState state = TryonState.idle;
  String? errorMessage;
  XFile? modelPhoto;
  XFile? garmentPhoto;

  GarmentCategory category = GarmentCategory.auto;
  TryonMode mode = TryonMode.balanced;
  String garmentPhotoType = "auto";

  List<TryonResultImage> results = [];

  final ImagePicker _picker = ImagePicker();
  final TryOnQuotaService quotaService;

  TryonViewModel(this.repo, {required this.quotaService});

  void setCategory(GarmentCategory c) { category = c; notifyListeners(); }
  void setMode(TryonMode m) { mode = m; notifyListeners(); }
  void setGarmentPhotoType(String t) { garmentPhotoType = t; notifyListeners(); }
   TryonStep step = TryonStep.model;

  bool get canNextFromModel => modelPhoto != null;
  bool get canNextFromGarment => garmentPhoto != null;
  bool get canSubmitFromConfirm =>
      modelPhoto != null && garmentPhoto != null && state != TryonState.processing;

  Future<void> pickModelPhoto() async {
    state = TryonState.picking; notifyListeners();
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (x != null) { modelPhoto = XFile(x.path); }
    state = TryonState.idle; notifyListeners();
  }

  Future<void> pickGarmentPhoto() async {
    state = TryonState.picking; notifyListeners();
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (x != null) { garmentPhoto = XFile(x.path); }
    state = TryonState.idle; notifyListeners();
  }

  // Sadece kotayı kontrol eder; state'i ERROR'a çekmez, iş başlatmaz.
Future<QuotaResult> checkQuotaOnly() async {
  final qr = await quotaService.tryConsumeOne();
  return qr;
}


  Future<void> submit() async {
    if (modelPhoto == null || garmentPhoto == null) {
      errorMessage = "Lütfen her iki görseli de seçin.";
      state = TryonState.error; notifyListeners(); return;
    }
    try {
      state = TryonState.uploading; notifyListeners();
      final modelUrl = await repo.uploadFile(modelPhoto!);
      final garmentUrl = await repo.uploadFile(garmentPhoto!);

      final req = TryonRequest(
        modelImageUrlOrDataUri: modelUrl,
        garmentImageUrlOrDataUri: garmentUrl,
        category: category,
        mode: mode,
        garmentPhotoType: garmentPhotoType,
        moderationLevel: "permissive",
        numSamples: 1,
        segmentationFree: true,
        outputFormat: "png",
        syncMode: true,
      );

      state = TryonState.processing; notifyListeners();
      final res = await repo.runTryOn(req);
      results = res.images;
      state = TryonState.done; notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      state = TryonState.error; notifyListeners();
    }
  }
  
  void goNext() {
    switch (step) {
      case TryonStep.model:
        if (!canNextFromModel) { _showStepError("Lütfen model fotoğrafını seçin."); return; }
        step = TryonStep.garment;
        break;
      case TryonStep.garment:
        if (!canNextFromGarment) { _showStepError("Lütfen kıyafet görselini seçin."); return; }
        step = TryonStep.confirm;
        break;
      case TryonStep.confirm:
        break;
    }
    notifyListeners();
  }

  void goBack() {
    switch (step) {
      case TryonStep.model: break;
      case TryonStep.garment: step = TryonStep.model; break;
      case TryonStep.confirm: step = TryonStep.garment; break;
    }
    notifyListeners();
  }

  void _showStepError(String msg) {
    errorMessage = msg;
    state = TryonState.error;
    notifyListeners();
  }

 // TryonViewModel.dart (örnek)
void reset() {
  step = TryonStep.model;
  modelPhoto = null;
  garmentPhoto = null;
  category = GarmentCategory.auto;
  mode = TryonMode.balanced;
  garmentPhotoType = 'auto';
  results.clear();
  state = TryonState.idle;
  errorMessage = null;
  notifyListeners();
}

  
}
