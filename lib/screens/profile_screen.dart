import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import '../db/database_helper.dart';
import '../pdf_helper.dart'; // ✅ PDF helper

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileImage();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final data = await DatabaseHelper.instance.getUserByEmail(email);
    setState(() {
      user = data;
      isLoading = false;
    });
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('profile_image');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  Future<void> _exportAsPDFWithFilters() async {
    final categoryOptions = ['All', 'Income', 'Expense'];
    String selectedCategory = 'All';
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Export PDF with Filters"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categoryOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => startDate = picked);
                        },
                        child: Text(startDate == null
                            ? 'Start Date'
                            : '${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => endDate = picked);
                        },
                        child: Text(endDate == null
                            ? 'End Date'
                            : '${endDate!.day}/${endDate!.month}/${endDate!.year}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final file = await PDFHelper.generateTransactionPdf(
                    user: user!,
                    categoryFilter: selectedCategory,
                    startDate: startDate,
                    endDate: endDate,
                  );

                  await Printing.sharePdf(
                    bytes: await file.readAsBytes(),
                    filename: file.path.split('/').last,
                  );
                },
                child: const Text("Generate PDF"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final username = user?['username'] ?? 'No user';
    final email = user?['email'] ?? 'No email';
    final phone = user?['phone'] ?? 'No phone';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/images/user.png') as ImageProvider,
                  ),
                  const SizedBox(height: 8),
                  const Text("Tap to change photo", style: TextStyle(color: Colors.blue, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildProfileDetail(Icons.email, "Email", email),
            _buildProfileDetail(Icons.phone, "Phone", phone),
            const SizedBox(height: 20),
            _buildProfileOption(Icons.settings, "Settings", () {
              Navigator.pushNamed(context, '/settings');
            }),
            _buildProfileOption(Icons.picture_as_pdf, "Export as PDF", _exportAsPDFWithFilters),
            _buildProfileOption(Icons.logout, "Logout", _logout, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
