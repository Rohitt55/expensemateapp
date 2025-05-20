import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _monthlyBudget;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget');
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _setMonthlyBudget() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Set Monthly Budget", style: TextStyle(fontSize: 16.sp)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Enter amount (৳)", labelStyle: TextStyle(fontSize: 14.sp)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('monthly_budget', value);
                setState(() => _monthlyBudget = value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Budget updated successfully!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _changePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Change Password", style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final oldPass = oldController.text.trim();
              final newPass = newController.text.trim();
              final confirmPass = confirmController.text.trim();

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New passwords do not match!")),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final email = prefs.getString('email') ?? '';
              final result = await DatabaseHelper.instance.updateUserPassword(email, oldPass, newPass);
              Navigator.pop(context);

              if (result > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password changed successfully!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Old password is incorrect.")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Reset", style: TextStyle(fontSize: 16.sp)),
        content: const Text("Delete all your transactions? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.resetAllTransactionsForUser();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All transaction data deleted.")),
              );
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        backgroundColor: const Color(0xFFFDF7F0),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionCard(
                icon: Icons.attach_money,
                title: "Set Monthly Budget",
                color: Colors.green,
                onTap: _setMonthlyBudget,
              ),
              _buildSwitchTile(
                icon: Icons.notifications_active,
                title: "Enable Notifications",
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                color: Colors.orange,
              ),
              _buildOptionCard(
                icon: Icons.lock,
                title: "Change Password",
                color: Colors.blue,
                onTap: _changePassword,
              ),
              _buildOptionCard(
                icon: Icons.delete_forever,
                title: "Reset All Data",
                color: Colors.red,
                onTap: _confirmReset,
                isDanger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 24.sp),
        title: Text(title, style: TextStyle(fontSize: 14.sp, color: isDanger ? Colors.red : Colors.black)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 3,
      child: SwitchListTile(
        secondary: Icon(icon, color: color, size: 24.sp),
        title: Text(title, style: TextStyle(fontSize: 14.sp)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
