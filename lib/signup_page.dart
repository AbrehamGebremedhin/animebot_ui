// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:animebot_ui/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animebot_ui/theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String email = '';
  String firstname = '';
  String password = '';
  bool isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.black45,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppTheme.backgroundContainer(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    label: 'Username',
                    onChanged: (value) => setState(() => username = value),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a username'
                        : null,
                  ),
                  _buildTextField(
                    label: 'Email',
                    onChanged: (value) => setState(() => email = value),
                    validator: _validateEmail,
                  ),
                  _buildTextField(
                    label: 'First Name',
                    onChanged: (value) => setState(() => firstname = value),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter your first name'
                        : null,
                  ),
                  _buildTextField(
                    label: 'Password',
                    onChanged: (value) => setState(() => password = value),
                    validator: _validatePassword,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });

                                final body = {
                                  "username": username,
                                  "email": email,
                                  "firstname": firstname,
                                  "password": password,
                                };

                                try {
                                  const String apiUrl =
                                      "http://192.168.45.208:8000/api/users/"; // Replace with your API endpoint
                                  final response = await http.post(
                                    Uri.parse(apiUrl),
                                    headers: {
                                      "Content-Type": "application/json"
                                    },
                                    body: json.encode(body),
                                  );

                                  if (response.statusCode == 201) {
                                    final responseData =
                                        json.decode(response.body);
                                    final userId =
                                        responseData["id"].toString();

                                    // Store the user ID in local storage
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString('userId', userId);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Signup successful!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Navigate to ProfileQuestionPage
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileQuestionPage(
                                          categories: [
                                            "user_info",
                                            "preferences",
                                            "hobbies",
                                            "story_preferences",
                                            "art_style_and_animation",
                                            "character_types",
                                            "maturity_and_content",
                                            "cultural_and_thematic_interests",
                                            "mood_and_emotional_preferences",
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    debugPrint("Error: ${response.body}");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Signup failed: ${response.reasonPhrase}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint("Exception: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Exception: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
