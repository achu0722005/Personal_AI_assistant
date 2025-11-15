import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';



class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> options;

  ChatMessage({required this.text, required this.isUser, this.options = const []});


  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'options': options,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    options: (json['options'] as List).map((i) => i.toString()).toList(),
  );
}

const Color background = Color(0xFF0D1117);
const Color chatBackground = Color(0xFF161B22);
const Color userMessageColor = Color(0xFF1F6FEB);
const Color botMessageColor = Color(0xFF30363D);
const Color hintTextColor = Color(0xFF8B949E);
const Color sendButtonColor = Color(0xFF238636);
const Color lightBackground = Color(0xFFFFFFFF);
const Color lightChatBackground = Color(0xFFF6F8FA);
const Color lightUserMessageColor = Color(0xFF2188FF);
const Color lightBotMessageColor = Color(0xFFE9EEF3);
const Color lightHintTextColor = Color(0xFF586069);
const Color lightSendButtonColor = Color(0xFF28A745);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const ChatBotApp(),
    ),
  );
}


class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Personal AI Chatbot",
      themeMode: themeNotifier.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const SplashScreen(),
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatContainer()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? background : lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/chatbot.png', width: 120),
            const SizedBox(height: 20),
            const Text("Personal AI Chatbot",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


class ChatContainer extends StatefulWidget {
  const ChatContainer({super.key});
  @override
  State<ChatContainer> createState() => _ChatContainerState();
}

class _ChatContainerState extends State<ChatContainer> {
  final GlobalKey<_ChatScreenState> _chatScreenKey = GlobalKey<_ChatScreenState>();
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChatWithAnimation());
  }

  Route _createPopupRoute() {
    final chatScreen = ChatScreen(key: _chatScreenKey);
    return PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, _) => chatScreen,
      transitionsBuilder: (context, animation, _, child) {
        const curve = Curves.elasticOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
        return ScaleTransition(scale: animation.drive(tween), child: child);
      },
    );
  }

  void _openChatWithAnimation() {
    if (!mounted) return;
    setState(() => _isChatOpen = true);
    Navigator.of(context).push(_createPopupRoute()).then((_) {
      if (!mounted) return;
      setState(() => _isChatOpen = false);
      _chatScreenKey.currentState?._inactivityTimer?.cancel();
    });
    _chatScreenKey.currentState?._startInactivityTimer();
  }

  void _minimizeChat() {
    if (_isChatOpen) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentBackground = Theme.of(context).brightness == Brightness.dark
        ? background
        : lightBackground;

    if (!_isChatOpen) {
      return Scaffold(
        backgroundColor: currentBackground,
        body: Center(
          child: Lottie.asset(
            'assets/chatbotnew.json',
            width: 420,
            height: 520,
            repeat: true,
            animate: true,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openChatWithAnimation,
          backgroundColor: sendButtonColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _minimizeChat();
        return false;
      },
      child: Scaffold(backgroundColor: currentBackground, body: const Center()),
    );
  }
}


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  Timer? _inactivityTimer;
  bool _isLoading = false;
  String _selectedLanguage = 'English';
  String _selectedPersonality = 'Study Buddy';


  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _speechText = '';
  double _speechVolume = 0.5;


  final Map<String, String> _offlineResponses = {
    "hi": "Hello! I'm in offline mode, but I can still chat. How can I help?",
    "hello": "Hello! I'm in offline mode, but I can still chat. How can I help?",
    "motivation": "You are capable of amazing things! Believe in yourself!",
    "study tips": "Focus on one topic at a time and take short breaks. You got this!",
    "offline": "I'm currently using local, pre-loaded data. The server is unreachable.",
    "how are you": "I'm doing great, thank you for asking! How are you feeling today?",
    "default": "The server is offline. Please try again later. (This is an offline response.)",
  };


  static const String _localEmulatorUrl = 'http://10.159.169.38:10000/chatbot';
  static const String _renderApiUrl = _localEmulatorUrl;


  static const String _websiteUrl = 'https://website-for-mini-project-sqv9.vercel.app/';

  final List<String> _topics = [
    'Health',
    'Goal Setting',
    'Technology',
    'Investing Tips',
    'Fitness Goals',
    'Motivation',
    'Travel',
    'Games',
    'Study-tips',
  ];


  final List<String> _languages = ['English', 'Hindi', 'Kannada', 'Malayalam'];


  final List<String> _personalities = [
    'Study Buddy', // Educational, formal
    'Wellness Coach', // Empathetic, motivational
    'Career Advisor', // Professional, advisory
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load memory on start
    _initTts();
    _initStt();
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text: 'Hi there! I’m your Personal AI assistant.\nAsk me anything or select a topic!',
        isUser: false,
      ));
    }
    _startInactivityTimer();
  }

  // --- Voice Chat (TTS & STT) ---

  Future<void> _initTts() async {
    // Determine language code based on selection
    String languageCode;

    if (_selectedLanguage == 'Hindi') {
      languageCode = 'hi-IN'; // Standard code for Hindi (India)
    } else if (_selectedLanguage == 'Kannada') {
      languageCode = 'kn-IN'; // Standard code for Kannada (India)
    } else if (_selectedLanguage == 'Malayalam') {
      languageCode = 'ml-IN'; // NEW: Standard code for Malayalam (India)
    } else {
      languageCode = 'en-US'; // Default to English
    }

    // Attempt to set the selected language code
    await flutterTts.setLanguage(languageCode);

    // Setting speech rate to 0.45 for a natural, slightly slow pace
    await flutterTts.setSpeechRate(0.45);

    await flutterTts.setVolume(_speechVolume);

    // Setting pitch to 1.2 for a friendly, slightly animated, and human-like tone
    await flutterTts.setPitch(1.2);
  }

  Future<void> _speak(String text) async {
    // Ensure TTS is initialized with the current language *before* speaking.
    await _initTts();

    if (_isListening) await _stopListening();
    await flutterTts.stop();
    // Clean up options before speaking
    final cleanText = _cleanText(text).replaceAll(RegExp(r'\*\*'), '');
    await flutterTts.speak(cleanText);
  }

  void _initStt() async {
    bool available = await _speech.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
    if (available) {
      debugPrint("Speech recognition is available");
    } else {
      debugPrint("Speech recognition is not available");
    }
  }

  void _startListening() async {
    if (!_speech.isAvailable) return;
    await flutterTts.stop();
    setState(() => _isListening = true);

    // Determine locale ID for STT
    String localeId;
    if (_selectedLanguage == 'Hindi') {
      localeId = 'hi_IN';
    } else if (_selectedLanguage == 'Kannada') {
      localeId = 'kn_IN';
    } else if (_selectedLanguage == 'Malayalam') {
      localeId = 'ml_IN'; // NEW: Standard locale for Malayalam
    } else {
      localeId = 'en_US';
    }

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _speechText = result.recognizedWords;
          if (result.finalResult) {
            _controller.text = _speechText;
            _sendMessage(_speechText);
            _speechText = ''; // Clear for next use
          }
        });
      },
      localeId: localeId,
    );
  }

  // FIX: Ensure this is Future<void> so it can be awaited in _speak()
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // --- External Link Launcher ---
  Future<void> _launchURL() async {
    final uri = Uri.parse(_websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback for errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the website: $_websiteUrl')),
      );
    }
    Navigator.of(context).pop(); // Close the drawer
  }

  // --- Chat Memory (Shared Preferences) ---

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('chatHistory', history);
    await prefs.setString('selectedLanguage', _selectedLanguage);
    await prefs.setString('selectedPersonality', _selectedPersonality);
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('chatHistory');
    final lang = prefs.getString('selectedLanguage');
    final personality = prefs.getString('selectedPersonality');

    if (lang != null) _selectedLanguage = lang;
    if (personality != null) _selectedPersonality = personality;

    if (history != null && history.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(history.map((s) => ChatMessage.fromJson(jsonDecode(s))).toList());
      });
      _scrollToBottom();
    }
  }

  // --- Core Chat Logic ---

  void _resetChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: 'Chat reset! I’m your $_selectedPersonality. How can I help you today?',
        isUser: false,
      ));
      _saveChatHistory();
    });
  }

  List<String> _extractOptions(String rawText) {
    final RegExp regex = RegExp(r'<<OPTION:([^>]+)>>');
    return regex.allMatches(rawText).map((m) => m.group(1)!).toList();
  }

  String _cleanText(String rawText) {
    final RegExp regex = RegExp(r'<<OPTION:[^>]+>>');
    return rawText.replaceAll(regex, '').trim();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    _stopListening();

    final aiInput = "$text (Current Personality: $_selectedPersonality. Respond in $_selectedLanguage)";

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();
    _inactivityTimer?.cancel();

    String? botReply;

    try {
      final response = await http.post(
        Uri.parse(_renderApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_input': aiInput,
          'language': _selectedLanguage,
          'personality': _selectedPersonality, // Send personality
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        botReply = data['response'] ?? "Sorry, I didn’t get that.";
      } else {
        throw Exception("Server status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error connecting to server: $e. Falling back to offline mode.");
      // Offline Mode Fallback
      final key = text.trim().toLowerCase();
      final offlineKey = _offlineResponses.keys.firstWhere(
            (k) => key.contains(k),
        orElse: () => 'default',
      );
      botReply = _offlineResponses[offlineKey] ?? _offlineResponses['default']!;
    }

    if (!mounted) return;

    final List<String> options = _extractOptions(botReply!);
    final String cleanReply = _cleanText(botReply);

    setState(() {
      _messages.add(ChatMessage(text: cleanReply, isUser: false, options: options));
      _isLoading = false;
      _saveChatHistory(); // Save history after new message
    });

    _scrollToBottom();
    _startInactivityTimer();
    _speak(cleanReply); // Speak the bot's reply
  }

  Future<void> _handleLanguageChange(String newLanguage) async {
    await flutterTts.stop();
    setState(() => _selectedLanguage = newLanguage);
    _initTts(); // Re-initialize TTS with new language
    // No need to call API here, just update chat
    setState(() {
      _messages.add(ChatMessage(text: "Language switched to $newLanguage. Personality: $_selectedPersonality", isUser: false));
      _saveChatHistory();
    });
  }

  void _handlePersonalityChange(String newPersonality) {
    setState(() {
      _selectedPersonality = newPersonality;
      _messages.add(ChatMessage(
        text: "Personality changed to **$newPersonality**! I will now adjust my tone accordingly.",
        isUser: false,
      ));
      _saveChatHistory();
    });
    Navigator.of(context).pop(); // Close drawer
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) {
        _sendMessage(
            "auto_reset_scroll"); // Send a silent message to refresh conversation on backend
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inactivityTimer?.cancel();
    flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // --- UI Building ---

  Widget _buildMessageWidget(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = msg.isUser
        ? (isDark ? userMessageColor : lightUserMessageColor)
        : (isDark ? botMessageColor : lightBotMessageColor);
    final textColor = isDark ? Colors.white : Colors.black; // Default text color outside bubbles (like action chips)

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment:
          msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row( // Use Row to place the message and speaker icon side-by-side
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SPEAKER ICON (Only for Bot Messages)
                if (!msg.isUser)
                  Container(
                    margin: const EdgeInsets.only(right: 8.0, top: 8.0),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.volume_up, color: Colors.white, size: 20),
                      // Call the speak function with this specific message text
                      onPressed: () => _speak(msg.text),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),

                // 2. MESSAGE BUBBLE
                Flexible(
                  child: Container(
                    constraints:
                    BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg.text,
                        // User message color is always white, Bot message color should be determined by theme
                        style: TextStyle(color: msg.isUser ? Colors.white : textColor, fontSize: 15)),
                  ),
                ),
              ],
            ),
            if (!msg.isUser && msg.options.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: msg.options.map((optionText) {
                    return ActionChip(
                      label: Text(optionText,
                          style: TextStyle(
                            // Ensure Action Chip text color is legible
                              color: textColor)),
                      backgroundColor:
                      isDark ? Colors.blueGrey.shade800 : lightBotMessageColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onPressed: () => _sendMessage(optionText),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentChatBackground = isDark ? chatBackground : lightChatBackground;
    final currentBackground = isDark ? background : lightBackground;
    final currentSendButtonColor = isDark ? sendButtonColor : lightSendButtonColor;

    return Scaffold(
      backgroundColor: currentChatBackground,
      appBar: AppBar(
        backgroundColor: currentBackground,
        title: Text("AI Chat (${_selectedPersonality})"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                color: Theme.of(context).appBarTheme.foregroundColor),
            tooltip: 'Reset Chat',
            onPressed: _resetChat,
          ),
          // Language Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: currentBackground,
              icon: Icon(Icons.language,
                  color: Theme.of(context).appBarTheme.foregroundColor),
              value: _selectedLanguage,
              items: _languages
                  .map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang,
                    style: TextStyle(
                        color: Theme.of(context)
                            .appBarTheme
                            .foregroundColor)),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) _handleLanguageChange(value);
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: currentBackground,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: currentSendButtonColor),
              child: const Center(
                child: Text("Personal AI Assistant",
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            // --- Personality Selector ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Personality Mode',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
            ..._personalities.map((mode) => ListTile(
              leading: Icon(
                  mode == 'Study Buddy'
                      ? Icons.school
                      : mode == 'Wellness Coach'
                      ? Icons.favorite
                      : Icons.work,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              title: Text(mode,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: _selectedPersonality == mode
                  ? Icon(Icons.check, color: currentSendButtonColor)
                  : null,
              onTap: () => _handlePersonalityChange(mode),
            )),
            const Divider(),
            // --- Theme Switch ---
            ListTile(
              leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              title: Text('Theme Mode',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => themeNotifier.toggleTheme(),
                activeColor: currentSendButtonColor,
              ),
            ),
            // --- About ---
            ListTile(
              leading: Icon(Icons.info,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              title: Text('About',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer first
                showAboutDialog(
                  context: context,
                  applicationName: 'Personal AI Chatbot',
                  applicationVersion: '1.0.0',
                  children: const [
                    Text(
                      "Developed by Team: Hack Street Boys\nYour personal AI assistant powered by Flask + Gemini API. Features: Voice Chat, Offline Mode, Personality Modes.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                );
              },
            ),
            // --- NEW: How to Use (Website Link) ---
            ListTile(
              leading: Icon(Icons.help_outline,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              title: Text('How to Use',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: _launchURL, // <<< CALLS THE URL LAUNCHER FUNCTION
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Topics/Chips (Unchanged)
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: _topics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ActionChip(
                    label: Text(topic),
                    backgroundColor: isDark
                        ? Colors.blueGrey.shade800
                        : Colors.blueGrey.shade200,
                    labelStyle:
                    TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => _sendMessage(topic),
                  ),
                );
              }).toList(),
            ),
          ),
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageWidget(_messages[index]),
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
            color: currentBackground,
            child: Row(
              children: [
                // Microphone button
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.red.withOpacity(0.15)
                        : currentSendButtonColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: _isListening
                        ? Lottie.asset(
                      'assets/mic_wave.json',
                      width: 40,
                      height: 40,
                      repeat: true,
                      animate: true,
                    )
                        : const Icon(Icons.mic, color: Colors.white),
                    onPressed: _isListening ? _stopListening : _startListening,
                    tooltip: _isListening ? 'Stop Recording' : 'Start Voice Chat',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening: $_speechText'
                          : 'Ask me anything...',
                      hintStyle: TextStyle(
                          color: isDark ? hintTextColor : lightHintTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white10
                          : Colors.grey.withOpacity(0.15),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                    readOnly: _isListening,
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                Container(
                  decoration: BoxDecoration(
                    color: currentSendButtonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}