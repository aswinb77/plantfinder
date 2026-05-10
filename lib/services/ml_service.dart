import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../services/database_service.dart';

class MLService {
  final ImageLabeler _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.05));

  /// Extracts the digital signature (labels & confidence scores) from an image
  Future<Map<String, double>> extractSignature(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
    
    // Ignore common background/noise words so the AI focuses ONLY on the plant
    final ignoreList = ["room", "table", "wall", "furniture", "hand", "finger", "sky", "floor", "wood", "desk", "indoor", "outdoor", "building", "person", "clothing"];

    Map<String, double> signature = {};
    for (ImageLabel label in labels) {
      if (!ignoreList.contains(label.label.toLowerCase())) {
        signature[label.label] = label.confidence;
      }
    }
    return signature;
  }

  /// Combines multiple signatures (from multiple angles) into one average signature
  Map<String, double> combineSignatures(List<Map<String, double>> signatures) {
    if (signatures.isEmpty) return {};
    
    Map<String, double> combined = {};
    for (var sig in signatures) {
      sig.forEach((key, value) {
        combined[key] = (combined[key] ?? 0.0) + value;
      });
    }
    
    // Average them out
    combined.forEach((key, value) {
      combined[key] = value / signatures.length;
    });
    
    return combined;
  }

  /// Calculates Cosine Similarity between two signatures. Returns a score between 0.0 and 1.0.
  double _cosineSimilarity(Map<String, double> sigA, Map<String, double> sigB) {
    Set<String> allKeys = {...sigA.keys, ...sigB.keys};
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (String key in allKeys) {
      double valA = sigA[key] ?? 0.0;
      double valB = sigB[key] ?? 0.0;
      
      dotProduct += valA * valB;
      normA += pow(valA, 2);
      normB += pow(valB, 2);
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Identifies the plant by extracting its signature and finding the closest match in Firestore
  Future<String?> identifyPlant(XFile image) async {
    // 1. Extract signature from the scanned image
    final scannedSignature = await extractSignature(image);
    if (scannedSignature.isEmpty) return null;

    // 2. Fetch all plants from database
    final plants = await DatabaseService().getAllPlants();
    if (plants.isEmpty) return null;

    // 3. Find the plant with the highest similarity score
    String? bestMatchId;
    double highestSimilarity = 0.0;

    for (var plant in plants) {
      if (plant.signature.isEmpty) continue;
      
      double similarity = _cosineSimilarity(scannedSignature, plant.signature);
      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatchId = plant.id;
      }
    }

    // Lowered threshold to 0.60 to allow for different lighting/angles
    if (highestSimilarity > 0.60) {
      return bestMatchId;
    }
    return null;
  }

  void dispose() {
    _imageLabeler.close();
  }
}
