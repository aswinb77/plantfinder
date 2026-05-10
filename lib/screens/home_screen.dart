import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../services/database_service.dart';
import 'plant_scanner_screen.dart';
import 'admin_login_screen.dart';
import 'edit_plant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _searchResults = [];
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _dbService.searchPlants(query.trim());
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Plant Analyzer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearch, // Search automatically as you type!
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search for a plant...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch("");
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Main Area (Either Empty State, Loading, or Search Results)
            Expanded(
              child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : _searchController.text.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 80, color: Colors.white24),
                          SizedBox(height: 16),
                          Text("Scan a plant or search by name", style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                    ? const Center(child: Text("No plants found.", style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final plant = _searchResults[index];
                          return _buildPlantCard(plant);
                        },
                      ),
            ),
          ],
        ),
      ),
      
      // The floating button is still the main scanner!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlantScannerScreen()),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.document_scanner, color: Colors.white),
        label: const Text("Scan Plant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(child: Icon(Icons.eco, size: 60, color: Colors.green)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      onPressed: () async {
                        final didUpdate = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditPlantScreen(plant: plant)),
                        );
                        if (didUpdate == true) {
                          _onSearch(_searchController.text); // Refresh search results
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${plant.basePrice.toStringAsFixed(2)}", 
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
