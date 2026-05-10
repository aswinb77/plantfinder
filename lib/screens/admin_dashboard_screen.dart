import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../main.dart'; 
import '../models/plant_model.dart';
import '../services/database_service.dart';
import '../services/ml_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  String _loadingText = "Uploading..."; // For the simulated training flow
  
  // We now store MULTIPLE images for "Training"
  List<XFile> _capturedImages = [];
  final int _maxPhotos = 5;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _additionalInfoController = TextEditingController(); // If the model finds it hard

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // The new Simulated Training Sequence
  void _savePlantAndTrain() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and price')),
      );
      return;
    }
    
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take at least 1 photo to train the model')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = "Extracting Image Features...";
    });

    try {
      // 1. Extract features using ML Kit
      final mlService = MLService();
      List<Map<String, double>> allSignatures = [];
      for (var img in _capturedImages) {
        final sig = await mlService.extractSignature(img);
        allSignatures.add(sig);
      }
      
      if (mounted) setState(() => _loadingText = "Compiling Neural Signature...");
      
      // 2. Combine into a master signature
      final finalSignature = mlService.combineSignatures(allSignatures);

      if (mounted) setState(() => _loadingText = "Saving to Database...");

      final newPlantId = _nameController.text.toLowerCase().replaceAll(' ', '_');
      
      final newPlant = Plant(
        id: newPlantId,
        name: _nameController.text,
        description: _additionalInfoController.text.isNotEmpty 
            ? _additionalInfoController.text 
            : "A beautiful new plant added to the database.", 
        basePrice: double.tryParse(_priceController.text) ?? 0.0,
        sizeMultipliers: {"Small": 1.0, "Medium": 1.5, "Large": 2.0}, // Default sizing
        signature: finalSignature,
      );

      await DatabaseService().addPlant(newPlant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully Trained & Uploaded ${_nameController.text}!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed! Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text("Train New Plant Data"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Camera View to take Reference Photo
            const Text("1. Take Training Photos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Take photos from different angles to improve AI accuracy.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),
            
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              clipBehavior: Clip.hardEdge,
              child: _isCameraInitialized 
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      
                      // Show how many photos are taken
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Text("${_capturedImages.length} / $_maxPhotos", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ),

                      Positioned(
                        bottom: 10, left: 0, right: 0,
                        child: CircleAvatar(
                          radius: 30, backgroundColor: _capturedImages.length >= _maxPhotos ? Colors.grey : Colors.green,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white), 
                            onPressed: _capturedImages.length >= _maxPhotos ? null : () async {
                                final image = await _controller!.takePicture();
                                setState(() => _capturedImages.add(image));
                            }
                          ),
                        ),
                      )
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 10),

            // Thumbnail Strip for multiple images
            if (_capturedImages.isNotEmpty)
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        image: DecorationImage(image: FileImage(File(_capturedImages[index].path)), fit: BoxFit.cover)
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _capturedImages.removeAt(index)),
                          child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),
            
            // 2. Data Entry Form
            const Text("2. Database & ML Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Plant Name (e.g., Ficus)"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Base Price (₹)"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _additionalInfoController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration("Additional Features (Optional)"),
            ),
            const SizedBox(height: 30),

            // Save & Train Button
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePlantAndTrain,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                child: _isLoading 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                        const SizedBox(width: 15),
                        Text(_loadingText, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text("Train & Upload to Server", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
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
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
    );
  }
}
