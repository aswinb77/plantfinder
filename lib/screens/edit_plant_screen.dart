import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../services/database_service.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;
  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.name);
    _priceController = TextEditingController(text: widget.plant.basePrice.toString());
    _descController = TextEditingController(text: widget.plant.description);
  }

  void _updatePlant() async {
    setState(() => _isLoading = true);
    
    final updatedPlant = Plant(
      id: widget.plant.id, // Keeping the same ID overwrites the old data in Firebase
      name: _nameController.text,
      description: _descController.text,
      basePrice: double.tryParse(_priceController.text) ?? widget.plant.basePrice,
      sizeMultipliers: widget.plant.sizeMultipliers, // keep existing sizes
    );

    // .set() in DatabaseService acts as an Update if the ID exists!
    await DatabaseService().addPlant(updatedPlant);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant Updated Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to tell Home Screen to refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text("Edit Plant Data"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.edit_note, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Plant Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration("Description"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Base Price (₹)"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePlant,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("Save Changes", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
    );
  }
}
