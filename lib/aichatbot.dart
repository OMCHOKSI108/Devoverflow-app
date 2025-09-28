import 'package:flutter/material.dart';

class AIChatBotScreen extends StatefulWidget {
  const AIChatBotScreen({Key? key}) : super(key: key);

  @override
  State<AIChatBotScreen> createState() => _AIChatBotScreenState();
}

class _AIChatBotScreenState extends State<AIChatBotScreen> {
  final List<Map<String, String>> _messages = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add({
      "from": "bot",
      "text": "Welcome to Devoverflow! How can I help you today?",
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({"from": "user", "text": text});
      _controller.clear();
    });

    // TODO: Replace with API call to real AI (ChatGPT/Gemini) later.
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _messages.add({
        "from": "bot",
        "text": "[Mock reply] I understood: $text",
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI ChatBot'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isBot = m['from'] == 'bot';
                return Align(
                  alignment: isBot
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isBot
                          ? Colors.grey.shade200
                          : const Color(0xFF667eea),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(
                        color: isBot ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask Devoverflow...',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendMessage,
                    backgroundColor: const Color(0xFF667eea),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
