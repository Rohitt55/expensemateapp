import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../db/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscure = true;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    final user = await DatabaseHelper.instance.loginUser(email, password);
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', user['email']);
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email or password is incorrect')));
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password", style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Registered Email")),
            TextField(controller: newPassController, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
            TextField(controller: confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: "Confirm Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final newPass = newPassController.text.trim();
              final confirm = confirmPassController.text.trim();

              if (newPass != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                return;
              }

              final result = await DatabaseHelper.instance.resetPassword(email, newPass);
              Navigator.pop(context);

              if (result > 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email not found.")));
              }
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50.h),
              Text("Hi, Welcome Back! 👋", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 30.h),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(fontSize: 14.sp)),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val!),
                  ),
                  Text("Remember Me", style: TextStyle(fontSize: 13.sp)),
                  const Spacer(),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _login,
                  child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 15.sp)),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don’t have an account?", style: TextStyle(fontSize: 13.sp)),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.blue, fontSize: 13.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
