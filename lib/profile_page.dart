// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:animebot_ui/theme/app_theme.dart';
import 'chat_page.dart';

class ProfileQuestionPage extends StatefulWidget {
  final List<String> categories;

  static const Map<String, String> categoryTitles = {
    "user_info": "User Information",
    "preferences": "Preferences",
    "hobbies": "Hobbies",
    "story_preferences": "Story Preferences",
    "art_style_and_animation": "Art Style and Animation",
    "character_types": "Character Types",
    "maturity_and_content": "Maturity and Content",
    "cultural_and_thematic_interests": "Cultural and Thematic Interests",
    "mood_and_emotional_preferences": "Mood and Emotional Preferences",
  };

  const ProfileQuestionPage({super.key, required this.categories});

  @override
  State<ProfileQuestionPage> createState() => _ProfileQuestionPageState();
}

class _ProfileQuestionPageState extends State<ProfileQuestionPage> {
  int currentCategoryIndex = 0;
  List<Map<String, dynamic>> questions = [];
  Map<String, String> fields = {}; // Holds the answers to be sent to the API
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  String get currentCategory => widget.categories[currentCategoryIndex];

  Future<void> _fetchQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    setState(() {
      isLoading = true;
    });

    try {
      const String apiUrl =
          "http://192.168.45.208:8000/api/profile/"; // Replace with your API URL

      var request = http.Request('GET', Uri.parse(apiUrl));
      request.headers.addAll({"Content-Type": "application/json"});
      request.body =
          json.encode({"user_id": userId, "category": currentCategory});

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(responseBody);
        setState(() {
          questions = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        _showErrorSnackBar(
            "Failed to load questions: ${response.reasonPhrase}");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId == null) {
      _showErrorSnackBar("User ID not found. Please log in again.");
      return;
    }

    final body = {
      "user_id": userId,
      "category": currentCategory,
      "fields": fields,
    };

    try {
      const String apiUrl =
          "http://192.168.45.208:8000/api/profile/"; // Replace with your API URL
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 202) {
        if (currentCategoryIndex < widget.categories.length - 1) {
          setState(() {
            currentCategoryIndex++;
            fields.clear();
          });
          _fetchQuestions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile setup completed!")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        }
      } else {
        _showErrorSnackBar(
            "Failed to submit answers: ${response.reasonPhrase}");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question["question"] ?? "",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (question["type"] == "open-ended")
              TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                onChanged: (value) {
                  fields[question["var_name"]] = value;
                },
              )
            else if (question["type"] == "multiple-choice")
              ...question["Options"].map<Widget>((option) {
                return RadioListTile(
                  title: Text(option),
                  value: option,
                  groupValue: fields[question["var_name"]],
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      fields[question["var_name"]] = value as String;
                    });
                  },
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ProfileQuestionPage.categoryTitles[currentCategory] ??
              "Profile Setup",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 0,
      ),
      body: AppTheme.backgroundContainer(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentCategoryIndex + 1) / widget.categories.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: questions.length,
                  itemBuilder: (context, index) =>
                      _buildQuestionCard(questions[index]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _submitAnswers,
        backgroundColor: AppTheme.primaryColor,
        label: Text(
          currentCategoryIndex < widget.categories.length - 1
              ? "Next"
              : "Finish",
          style: const TextStyle(color: Colors.black),
        ),
        icon: const Icon(Icons.arrow_forward, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
