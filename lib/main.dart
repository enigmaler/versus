import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For copy to clipboard
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(QuranChatApp());

class QuranChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Chat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.teal[800]),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    QuranScreen(),
    ChatScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.menu_book), label: "Quran"),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.favorite), label: "Favorites"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ======= CHAT PAGE =======
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  // For demo, we store favorites here. Use Provider/shared_prefs/db in real apps.
  static List<String> favorites = [];

  Future<String> askDeepSeek(String question) async {
    // API key is provided via --dart-define to avoid committing secrets.
    const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    const apiUrl = 'https://api.deepseek.com/v1/chat/completions';

    final body = jsonEncode({
      "model": "deepseek-chat",
      "messages": [
        {
          "role": "system",
          "content": "You are an Islamic scholar and Quran expert. Answer all questions based on the Quran and reliable tafsir. If a question is not related to Islam, politely refuse."
        },
        {
          "role": "user",
          "content": question
        }
      ]
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'].toString().trim();
    } else {
      return 'Sorry, something went wrong. Please try again later.';
    }
  }

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isLoading = true;
      _controller.clear();
    });

    final reply = await askDeepSeek(text);

    setState(() {
      _messages.add(_ChatMessage(reply, false));
      _isLoading = false;
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied!')));
  }

  void _favoriteMessage(String text) {
    setState(() {
      if (!favorites.contains(text)) {
        favorites.add(text);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to favorites!')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran Chat'),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.pink[300]),
            onPressed: () {
              setState(() {});
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.teal[50],
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask any Quranic question!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                SizedBox(height: 4),
                Text("AI-powered, based on the Quran and tafsir.",
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: msg.isUser ? Colors.teal[100] : Colors.white,
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: msg.isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(msg.text),
                          if (!msg.isUser)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.copy, size: 18),
                                  onPressed: () => _copyMessage(msg.text),
                                  tooltip: 'Copy',
                                ),
                                IconButton(
                                  icon: Icon(Icons.favorite, color: Colors.pink[300], size: 18),
                                  onPressed: () => _favoriteMessage(msg.text),
                                  tooltip: 'Favorite',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about the Quran...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}

// ======= HOME PAGE =======
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _ayah = '“Indeed, prayer prohibits immorality and wrongdoing.” (Quran 29:45)';
  bool _loading = false;
  Map<String, String>? _prayerTimes;
  bool _prayerLoading = false;

  // For demo: Hardcoded ayahs. For real: fetch from Quran API!
  final List<String> ayahs = [
    '“Indeed, prayer prohibits immorality and wrongdoing.” (Quran 29:45)',
    '“And He found you lost and guided [you].” (Quran 93:7)',
    '“So remember Me; I will remember you.” (Quran 2:152)',
    '“Allah does not burden a soul beyond that it can bear.” (Quran 2:286)',
    '“Verily, with hardship comes ease.” (Quran 94:6)'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() => _prayerLoading = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Use Makkah coordinates as fallback
        final lat = 21.3891;
        final lng = 39.8579;
        await _requestTimes(lat, lng);
      } else {
        final pos = await Geolocator.getCurrentPosition();
        await _requestTimes(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // ignore errors for demo
    }
    setState(() => _prayerLoading = false);
  }

  Future<void> _requestTimes(double lat, double lng) async {
    final now = DateTime.now();
    final url =
        'https://api.aladhan.com/v1/timings/${now.millisecondsSinceEpoch ~/ 1000}?latitude=$lat&longitude=$lng&method=2';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final timings = Map<String, dynamic>.from(data['data']['timings']);
      setState(() {
        _prayerTimes = {
          'Fajr': timings['Fajr'],
          'Dhuhr': timings['Dhuhr'],
          'Asr': timings['Asr'],
          'Maghrib': timings['Maghrib'],
          'Isha': timings['Isha'],
        };
      });
    }
  }

  void _newAyah() async {
    setState(() => _loading = true);
    await Future.delayed(Duration(milliseconds: 500));
    ayahs.shuffle();
    setState(() {
      _ayah = ayahs.first;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Scaffold(
      appBar: AppBar(title: Text('Home'), elevation: 1),
      body: Center(
        child: Card(
          color: Colors.teal[50],
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Salam, $greeting!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal[800])),
                SizedBox(height: 20),
                if (_prayerTimes != null)
                  Column(
                    children: [
                      Text('Prayer Times',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                              fontSize: 16)),
                      SizedBox(height: 8),
                      for (final e in _prayerTimes!.entries) Text('${e.key}: ${e.value}'),
                      SizedBox(height: 20),
                    ],
                  )
                else if (_prayerLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                Text("Today's Ayah",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800], fontSize: 18)),
                SizedBox(height: 14),
                _loading
                    ? CircularProgressIndicator()
                    : Text(
                  _ayah,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _newAyah,
                  icon: Icon(Icons.refresh),
                  label: Text('New Verse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[300],
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======= QURAN PAGE =======
class QuranScreen extends StatefulWidget {
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<dynamic> _surahs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  Future<void> _fetchSurahs() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.quran.com/api/v4/chapters'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _surahs = data['chapters'];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quran'), elevation: 1),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _surahs.length,
              itemBuilder: (context, index) {
                final s = _surahs[index];
                return ListTile(
                  title: Text('${s['name_simple']}'),
                  subtitle: Text('Ayahs: ${s['verses_count']}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahPage(
                        id: s['id'],
                        name: s['name_simple'],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SurahPage extends StatefulWidget {
  final int id;
  final String name;

  const SurahPage({required this.id, required this.name});

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  List<dynamic> _verses = [];
  bool _loading = true;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _fetchVerses();
  }

  Future<void> _fetchVerses() async {
    try {
      final url =
          'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=${widget.id}&translations=131';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _verses = data['verses'];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.language),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _verses.length,
              itemBuilder: (context, index) {
                final v = _verses[index];
                return ListTile(
                  title: Text(v['text_uthmani'] ?? ''),
                  subtitle: _showTranslation && v['translations'] != null && v['translations'].isNotEmpty
                      ? Text(v['translations'][0]['text'] ?? '')
                      : null,
                );
              },
            ),
    );
  }
}

// ======= FAVORITES PAGE =======
class FavoritesScreen extends StatefulWidget {
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    // For demo, use static list in Chat. For real, persist with shared_prefs/db.
    final favorites = _ChatScreenState.favorites;
    return Scaffold(
      appBar: AppBar(title: Text('Favorites'), elevation: 1),
      body: favorites.isEmpty
          ? Center(child: Text('No favorites yet.'))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) => Card(
          color: Colors.teal[50],
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            title: Text(favorites[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  favorites.removeAt(index);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ======= PROFILE PAGE =======
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), elevation: 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 70, color: Colors.teal[200]),
            SizedBox(height: 10),
            Text(
              "Guest User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "More profile features coming soon...",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
