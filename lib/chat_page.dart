import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    _fetchInitialMessage();
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
        Uri.parse('http://192.168.12.208:8000/api/chat/'),
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
        Uri.parse('http://192.168.12.208:8000/api/chat/'),
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
        backgroundColor: Colors.pinkAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/anime_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.recommend, color: Colors.tealAccent),
                    onPressed: _sendRecommendRequest,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter your message',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide:
                              BorderSide(color: Colors.black.withOpacity(0.5)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.tealAccent),
                    onPressed: () {
                      _sendMessage(_controller.text);
                      _controller.clear();
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
    final color = isUser ? Colors.blueGrey : Colors.white;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        if (!isUser) ...[
          CircleAvatar(
            backgroundImage: AssetImage(avatar),
          ),
          const SizedBox(width: 10),
        ],
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
          ),
          child: Text(
            message['text'],
            style: TextStyle(
              fontFamily: 'AnimeFont',
              color: isUser ? Colors.black : Colors.black,
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: AssetImage(avatar),
          ),
        ],
      ],
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
