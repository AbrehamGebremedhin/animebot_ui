// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
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
          "http://192.168.12.208:8000/api/profile/"; // Replace with your API URL

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
          "http://192.168.12.208:8000/api/profile/"; // Replace with your API URL
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Questions: ${ProfileQuestionPage.categoryTitles[currentCategory]}",
          style: GoogleFonts.pacifico(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/anime_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        (currentCategoryIndex + 1) / widget.categories.length,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final questionText = question["question"] ?? "";
                        final questionType = question["type"] ?? "";
                        final options = question["Options"];
                        final varName = question["var_name"] ?? "";

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questionText,
                                style: TextStyle(
                                  color: Colors.teal[
                                      500], // Equivalent to Colors.teal[900]
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 3.0,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (questionType == "open-ended")
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelStyle:
                                        TextStyle(color: Colors.teal[500]),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    fields[varName] = value;
                                  },
                                )
                              else if (questionType == "multiple-choice")
                                ...options.map<Widget>((option) {
                                  return RadioListTile(
                                    title: Text(option,
                                        style:
                                            TextStyle(color: Colors.teal[500])),
                                    value: option,
                                    groupValue: fields[varName],
                                    onChanged: (value) {
                                      setState(() {
                                        fields[varName] = value as String;
                                      });
                                    },
                                  );
                                }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitAnswers,
          child: Text(currentCategoryIndex < widget.categories.length - 1
              ? "Next"
              : "Finish"),
        ),
      ),
    );
  }
}
