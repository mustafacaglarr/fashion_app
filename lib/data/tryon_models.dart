// lib/data/tryon_models.dart
enum GarmentCategory { tops, bottoms, onePieces, auto }
enum TryonMode { performance, balanced, quality }

GarmentCategory catFromString(String s) {
  switch (s) {
    case "tops": return GarmentCategory.tops;
    case "bottoms": return GarmentCategory.bottoms;
    case "one-pieces": return GarmentCategory.onePieces;
    default: return GarmentCategory.auto;
  }
}

String catToString(GarmentCategory c) {
  switch (c) {
    case GarmentCategory.tops: return "tops";
    case GarmentCategory.bottoms: return "bottoms";
    case GarmentCategory.onePieces: return "one-pieces";
    case GarmentCategory.auto: default: return "auto";
  }
}

String modeToString(TryonMode m) {
  switch (m) {
    case TryonMode.performance: return "performance";
    case TryonMode.quality: return "quality";
    case TryonMode.balanced:
    default: return "balanced";
  }
}

class TryonRequest {
  final String modelImageUrlOrDataUri;
  final String garmentImageUrlOrDataUri;
  final GarmentCategory category;
  final TryonMode mode;
  final String garmentPhotoType; // "auto" | "model" | "flat-lay"
  final String moderationLevel;  // "permissive" | "none" | "conservative"
  final int numSamples;
  final bool segmentationFree;
  final String outputFormat; // "png" | "jpeg"
  final bool syncMode;

  TryonRequest({
    required this.modelImageUrlOrDataUri,
    required this.garmentImageUrlOrDataUri,
    this.category = GarmentCategory.auto,
    this.mode = TryonMode.balanced,
    this.garmentPhotoType = "auto",
    this.moderationLevel = "permissive",
    this.numSamples = 1,
    this.segmentationFree = true,
    this.outputFormat = "png",
    this.syncMode = true,
  });

  Map<String, dynamic> toFalInputJson() => {
        "model_image": modelImageUrlOrDataUri,
        "garment_image": garmentImageUrlOrDataUri,
        "category": catToString(category),
        "mode": modeToString(mode),
        "garment_photo_type": garmentPhotoType,
        "moderation_level": moderationLevel,
        "num_samples": numSamples,
        "segmentation_free": segmentationFree,
        "output_format": outputFormat,
        "sync_mode": syncMode,
      };
}

class TryonResultImage {
  final String url;
  TryonResultImage(this.url);
}

class TryonResult {
  final List<TryonResultImage> images;
  TryonResult(this.images);
}
