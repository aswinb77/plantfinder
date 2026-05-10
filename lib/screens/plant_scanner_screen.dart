import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart'; 
import '../services/ml_service.dart';
import '../services/database_service.dart';
import '../models/plant_model.dart';

class PlantScannerScreen extends StatefulWidget {
  const PlantScannerScreen({super.key});

  @override
  State<PlantScannerScreen> createState() => _PlantScannerScreenState();
}

class _PlantScannerScreenState extends State<PlantScannerScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // Add processing state

  // Instantiate our services
  final _mlService = MLService();
  final _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  // The logic for Step 5!
  Future<void> _captureAndAnalyze() async {
    if (!_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Take Photo
      final image = await _controller!.takePicture();
      
      // 2. Run the Mock ML Model
      final plantId = await _mlService.identifyPlant(image);
      
      if (plantId != null) {
        // 3. Fetch Data from the Mock DB
        final plantData = await _dbService.getPlantDetails(plantId);
        
        if (plantData != null && mounted) {
          // 4. Slide up the Results UI
          _showResultsBottomSheet(plantData);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plant not found in database!'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // The Bottom Sheet UI
  void _showResultsBottomSheet(Plant plant) {
    String selectedSize = "Small"; // Default size
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to be taller
      backgroundColor: Colors.grey[900], // Sleek dark look
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        // StatefulBuilder allows us to update the UI inside the bottom sheet
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final finalPrice = plant.calculatePrice(selectedSize);
            
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Little drag handle
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Plant Data
                  Text(plant.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(plant.description, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  const SizedBox(height: 24),
                  
                  // Dynamic Size Selector
                  const Text("Select Size:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: plant.sizeMultipliers.keys.map((size) {
                      final isSelected = selectedSize == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        selectedColor: Colors.green,
                        onSelected: (selected) {
                          if (selected) {
                            // Update the size, which triggers a UI rebuild to update the price!
                            setSheetState(() => selectedSize = size);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  
                  // Price Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${finalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("Done", style: TextStyle(fontSize: 18, color: Colors.white)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Plant', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, 
      
      body: _isCameraInitialized && _controller != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: _isProcessing ? Colors.orange : Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 150,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
          
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isProcessing ? null : _captureAndAnalyze,
        backgroundColor: _isProcessing ? Colors.grey : Colors.green,
        shape: const CircleBorder(),
        child: _isProcessing 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.camera_alt, size: 40, color: Colors.white),
      ),
    );
  }
}
