import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final Map<String, double> sizeMultipliers;
  final Map<String, double> signature;

  Plant({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.sizeMultipliers,
    this.signature = const {},
  });

  // Calculate final price based on selected size
  double calculatePrice(String size) {
    double multiplier = sizeMultipliers[size] ?? 1.0;
    return basePrice * multiplier;
  }

  // Convert Firebase Document to Plant Object
  factory Plant.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    // Safety check for sizeMultipliers
    Map<String, double> parsedMultipliers = {};
    if (data['sizeMultipliers'] != null) {
      (data['sizeMultipliers'] as Map).forEach((key, value) {
        parsedMultipliers[key.toString()] = (value as num).toDouble();
      });
    } else {
      parsedMultipliers = {"Small": 1.0, "Medium": 1.5, "Large": 2.0}; // Default fallback
    }

    return Plant(
      id: doc.id,
      name: data['name'] ?? 'Unknown Plant',
      description: data['description'] ?? 'No description available.',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      sizeMultipliers: parsedMultipliers,
      signature: Map<String, double>.from(data['signature'] ?? {}),
    );
  }

  // Convert Plant Object to Firebase Document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'sizeMultipliers': sizeMultipliers,
      'signature': signature,
    };
  }
}
