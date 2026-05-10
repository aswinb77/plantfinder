import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    // Simulate checking database for password
    await Future.delayed(const Duration(seconds: 1)); 
    
    // Hardcoded simple password for prototype
    if (_passwordController.text == "admin123") {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid password! Hint: admin123'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text("Admin Access"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 30),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Master Password",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
