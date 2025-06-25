import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/main_navigation.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: adaptivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                SizedBox(height: screenHeightPct(context, 0.05)),
                const Text(
                  'cord',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your one-stop music hub - no more\njuggling multiple apps, just create',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: screenHeightPct(context, 0.06)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                    'Create your Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                    SizedBox(height: screenHeightPct(context, 0.025)),
                    Container(
                      width: screenWidthPct(context, 0.8),
                      child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: screenWidthPct(context, 0.8),
                  child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: screenWidthPct(context, 0.8),
                  child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 160,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.pink],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(1.2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (_passwordController.text == _confirmPasswordController.text) {
                              setState(() { _isLoading = true; });
                              try {
                                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                );
                                setState(() { _isLoading = false; });
                                Get.snackbar('Success', 'Account created successfully!',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                                await Future.delayed(Duration(seconds: 1)); // Give user time to see the message
                                Get.off(() => MainNavigation());
                              } on FirebaseAuthException catch (e) {
                                setState(() { _isLoading = false; });
                                Get.snackbar('Sign Up Failed', e.message ?? 'Unknown error',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            } else {
                              Get.snackbar('Error', 'Passwords do not match',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                      'Next',
                      style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.normal,
                        fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Or sign up with',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/social_logos.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
