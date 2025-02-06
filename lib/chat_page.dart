import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animebot_ui/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String? userId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    if (userId != null) {
      _fetchInitialMessage();
    }
  }

  Future<void> _fetchInitialMessage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.45.208:8000/api/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'reply': "",
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.add({
            'text': json.decode(response.body)['question'],
            'isUser': false,
          });
        });
        _scrollToBottom();
      } else {
        setState(() {
          _errorMessage = 'Failed to load initial message';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'text': message, 'isUser': true});
      _isLoading = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.45.208:8000/api/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'reply': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (message == '/recommend') {
          // Handle recommendation response
          final recommendations = responseData as List<dynamic>;
          for (var recommendation in recommendations) {
            setState(() {
              _messages.add({
                'isRecommendation': true,
                'recommendation': recommendation,
              });
            });
          }
        } else {
          // Handle normal message response
          setState(() {
            _messages.add({
              'text': responseData['question'],
              'isUser': false,
            });
          });
        }
        _scrollToBottom();
      } else {
        setState(() {
          _errorMessage = 'Failed to send message';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendRecommendRequest() {
    _sendMessage('/recommend');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anime Chat"),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 0,
      ),
      body: AppTheme.backgroundContainer(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message['isRecommendation'] == true) {
                    return _buildRecommendation(message['recommendation']);
                  }
                  return _buildMessage(message);
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.recommend,
                        color: AppTheme.primaryColor),
                    onPressed: _sendRecommendRequest,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your message',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.white.withOpacity(0.6)),
                          onPressed: () => _controller.clear(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'];
    final avatar = isUser ? 'assets/user_avatar.png' : 'assets/bot_avatar.png';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) _buildAvatar(avatar),
          Expanded(
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(
                  left: isUser ? 50 : 8,
                  right: isUser ? 8 : 50,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppTheme.primaryColor.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 0),
                    bottomRight: Radius.circular(isUser ? 0 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['text'],
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) _buildAvatar(avatar),
        ],
      ),
    );
  }

  Widget _buildAvatar(String path) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildRecommendation(Map<String, dynamic> recommendation) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Image.network(recommendation['image_url']),
            const SizedBox(height: 5),
            Text(recommendation['synopsis']),
            const SizedBox(height: 5),
            Wrap(
              spacing: 5.0,
              runSpacing: 5.0,
              children: [
                Chip(label: Text('Aired: ${recommendation['aired']}')),
                Chip(label: Text('Show Status: ${recommendation['status']}')),
                Chip(
                    label: Text(
                        'Episode Duration: ${recommendation['duration']}')),
                Chip(
                    label: Text(
                        'Total Episodes: ${recommendation['no_episodes']}')),
                Chip(
                    label: Text(
                        'Show Rating: ${recommendation['rating'].join(', ')}')),
                Chip(
                    label: Text(
                        'Show Type: ${recommendation['type'].join(', ')}')),
                Chip(
                    label: Text(
                        'Adapted from: ${recommendation['sourced_from'].join(', ')}')),
                Chip(
                    label:
                        Text('Genres: ${recommendation['genres'].join(', ')}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
