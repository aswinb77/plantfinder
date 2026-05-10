import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch a specific plant from Firestore (used by Scanner)
  Future<Plant?> getPlantDetails(String plantId) async {
    try {
      DocumentSnapshot doc = await _db.collection('plants').doc(plantId).get();
      if (doc.exists) {
        return Plant.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint("Error fetching plant details from Firebase: \$e");
    }
    return null;
  }

  /// Fetch all plants from Firestore (used by Home Screen)
  Future<List<Plant>> getAllPlants() async {
    try {
      QuerySnapshot snapshot = await _db.collection('plants').get();
      return snapshot.docs.map((doc) => Plant.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching catalog from Firebase: \$e");
      return [];
    }
  }

  /// Upload a new plant to Firestore (used by Admin Dashboard)
  Future<void> addPlant(Plant plant) async {
    try {
      await _db.collection('plants').doc(plant.id).set(plant.toMap());
    } catch (e) {
      debugPrint("Error adding plant to Firebase: \$e");
      rethrow;
    }
  }

  /// Search plants by name (used by Home Screen Search Bar)
  Future<List<Plant>> searchPlants(String query) async {
    if (query.isEmpty) return [];
    try {
      QuerySnapshot snapshot = await _db.collection('plants').get();
      return snapshot.docs
          .map((doc) => Plant.fromFirestore(doc))
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint("Error searching Firebase: \$e");
      return [];
    }
  }
}
