import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../db/database_helper.dart';
import '../pdf_helper.dart';

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
            title: Text("Export PDF with Filters", style: TextStyle(fontSize: 16.sp)),
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
                SizedBox(height: 10.h),
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
    await prefs.remove('email');
    await prefs.remove('isLoggedIn');
    // ✅ এই লাইনটি বাদ দেওয়া হয়েছে:
    // await prefs.remove('profile_image');
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
        title: Text("Profile", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/user.png') as ImageProvider,
                      ),
                      SizedBox(height: 8.h),
                      Text("Tap to change photo", style: TextStyle(color: Colors.blue, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      Text(email, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                      Text(username, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                _buildProfileDetail(Icons.email, "Email", email),
                _buildProfileDetail(Icons.phone, "Phone", phone),
                SizedBox(height: 10.h),
                _buildProfileOption(Icons.settings, "Settings", () {
                  Navigator.pushNamed(context, '/settings');
                }),
                _buildProfileOption(Icons.picture_as_pdf, "Export as PDF", _exportAsPDFWithFilters),
                _buildProfileOption(Icons.logout, "Logout", _logout, color: Colors.redAccent),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: Icon(icon, size: 24.sp),
        title: Text(label, style: TextStyle(fontSize: 14.sp)),
        subtitle: Text(value, style: TextStyle(fontSize: 12.sp)),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 24.sp),
        title: Text(title, style: TextStyle(color: color, fontSize: 14.sp)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
      ),
    );
  }
}
