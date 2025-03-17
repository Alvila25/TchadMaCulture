import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import 'package:charts_flutter/flutter.dart' as charts; // For admin charts
import 'package:speech_to_text/speech_to_text.dart' as stt; // Voice input
import 'package:shared_preferences/shared_preferences.dart'; // Theme persistence

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initNotifications();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: TelehealthTCDApp(),
    ),
  );
}

// Notifications
FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _notifications.initialize(settings, onSelectNotification: (payload) async {
    // Handle notification tap (e.g., navigate to appointment)
  });
}

// Theme Provider
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }
}

// Auth Provider
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _role;
  User? get user => _user;
  String? get role => _role;

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        _role = doc.exists ? doc['role'] : 'patient';
      } else {
        _role = null;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String role) async {
    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({'role': role, 'email': email, 'status': 'offline', 'onboarded': false});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

// Offline Provider
class OfflineProvider with ChangeNotifier {
  late Database _db;
  final _firestore = FirebaseFirestore.instance;

  OfflineProvider() {
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'telehealth.db'),
      onCreate: (db, version) {
        db.execute('CREATE TABLE appointments(id INTEGER PRIMARY KEY, userId TEXT, doctorId TEXT, date TEXT, status TEXT)');
        db.execute('CREATE TABLE records(id INTEGER PRIMARY KEY, patientId TEXT, diagnosis TEXT, prescription TEXT)');
        db.execute('CREATE TABLE chats(id INTEGER PRIMARY KEY, chatId TEXT, sender TEXT, text TEXT)');
      },
      version: 1,
    );
  }

  Future<void> cacheAppointment(String userId, String doctorId, String date, String status) async {
    await _db.insert('appointments', {'userId': userId, 'doctorId': doctorId, 'date': date, 'status': status});
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCachedAppointments(String userId) async {
    return await _db.query('appointments', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> cacheRecord(String patientId, String diagnosis, String prescription) async {
    await _db.insert('records', {'patientId': patientId, 'diagnosis': diagnosis, 'prescription': prescription});
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCachedRecords(String patientId) async {
    return await _db.query('records', where: 'patientId = ?', whereArgs: [patientId]);
  }

  Future<void> cacheChat(String chatId, String sender, String text) async {
    await _db.insert('chats', {'chatId': chatId, 'sender': sender, 'text': text});
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCachedChats(String chatId) async {
    return await _db.query('chats', where: 'chatId = ?', whereArgs: [chatId]);
  }

  Future<void> syncOfflineData(String userId) async {
    final appointments = await getCachedAppointments(userId);
    for (var appt in appointments) {
      await _firestore.collection('appointments').add({
        'userId': appt['userId'],
        'doctorId': appt['doctorId'],
        'date': appt['date'],
        'status': appt['status'],
      });
      await _db.delete('appointments', where: 'id = ?', whereArgs: [appt['id']]);
    }

    final records = await getCachedRecords(userId);
    for (var record in records) {
      await _firestore.collection('health_records').add({
        'patientId': record['patientId'],
        'diagnosis': record['diagnosis'],
        'prescription': record['prescription'],
        'doctor': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _db.delete('records', where: 'id = ?', whereArgs: [record['id']]);
    }

    notifyListeners();
  }
}

// Main App
class TelehealthTCDApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Telehealth-TCD',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        textTheme: TextTheme(bodyText2: TextStyle(color: Colors.teal[800])),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en', ''), Locale('fr', ''), Locale('es', '')],
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) => auth.user == null
            ? AuthScreen()
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(auth.user!.uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final onboarded = snapshot.data!['onboarded'] ?? false;
                  return onboarded ? HomeScreen() : OnboardingScreen();
                },
              ),
      ),
    );
  }
}

// Onboarding Screen
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(context, 'Welcome to Telehealth-TCD', 'Your health, our priority.', Icons.favorite),
              _buildPage(context, 'Connect with Doctors', 'Video, chat, and more.', Icons.video_call),
              _buildPage(context, 'Stay Healthy', 'Learn and manage your care.', Icons.book),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () => _controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: Text('Back'),
                  ),
                Row(
                  children: List.generate(3, (index) => _buildDot(index)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == 2) {
                      await FirebaseFirestore.instance.collection('users').doc(authProvider.user!.uid).update({'onboarded': true});
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                    } else {
                      _controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.teal),
          SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.teal : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Auth Screen
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _role = 'patient';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal[100]!, Colors.teal[300]!], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isLogin ? 'Welcome Back' : 'Join Us', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white.withOpacity(0.8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white.withOpacity(0.8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              obscureText: true,
            ),
            if (!_isLogin)
              DropdownButton<String>(
                value: _role,
                items: ['patient', 'doctor', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (value) => setState(() => _role = value!),
              ),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.redAccent)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (_isLogin) {
                    await authProvider.signIn(_emailController.text.trim(), _passwordController.text.trim());
                  } else {
                    await authProvider.signUp(_emailController.text.trim(), _passwordController.text.trim(), _role);
                  }
                } catch (e) {
                  setState(() => _error = e.toString());
                }
              },
              child: Text(_isLogin ? 'Login' : 'Register'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Need an account? Register' : 'Already have an account? Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final offlineProvider = Provider.of<OfflineProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Telehealth-TCD'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => offlineProvider.syncOfflineData(authProvider.user!.uid),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async => await authProvider.signOut(),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal[200]!, Colors.teal[400]!], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildTile(context, 'Consultation', Icons.video_call, VideoConsultationScreen()),
              _buildTile(context, 'Chat', Icons.chat, DoctorListScreen()),
              _buildTile(context, 'Appointments', Icons.calendar_today, AppointmentScreen()),
              _buildTile(context, 'Records', Icons.folder, HealthRecordsScreen()),
              _buildTile(context, 'Payments', Icons.payment, PaymentScreen()),
              _buildTile(context, 'Emergency', Icons.local_hospital, EmergencyScreen(), color: Colors.redAccent),
              _buildTile(context, 'Learn', Icons.book, EducationalContentScreen()),
              if (authProvider.role == 'admin') _buildTile(context, 'Admin', Icons.admin_panel_settings, AdminDashboardScreen()),
              _buildTile(context, 'Symptoms', Icons.health_and_safety, SymptomCheckerScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, Widget screen, {Color? color}) {
    return OpenContainer(
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      closedColor: Colors.white.withOpacity(0.2),
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: Duration(milliseconds: 400),
      closedBuilder: (context, action) => InkWell(
        onTap: action,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color ?? Colors.teal),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      openBuilder: (context, action) => screen,
    );
  }
}

// Doctor List Screen
class DoctorListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: Text('Doctors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final doctors = snapshot.data!.docs;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(doctor['email']),
                subtitle: Text(doctor['status'] == 'online' ? 'Online' : 'Offline'),
                trailing: Icon(doctor['status'] == 'online' ? Icons.circle : Icons.circle_outlined, color: doctor['status'] == 'online' ? Colors.green : Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(doctorId: doctors[index].id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Video Consultation Screen
class VideoConsultationScreen extends StatefulWidget {
  @override
  _VideoConsultationScreenState createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  final _channelController = TextEditingController();
  bool _joined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    await AgoraRtcEngine.create('YOUR_AGORA_APP_ID');
    await AgoraRtcEngine.enableVideo();
    await AgoraRtcEngine.setParameters('{"che.video.lowBitRateStreamParameter":{"width":320,"height":180,"frameRate":15,"bitRate":140}}');
    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) => setState(() => _remoteUid = uid);
    AgoraRtcEngine.onUserOffline = (int uid, int reason) => setState(() => _remoteUid = null);
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'status': 'online'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Consultation')),
      body: Column(
        children: [
          TextField(
            controller: _channelController,
            decoration: InputDecoration(labelText: 'Enter Channel Name', border: OutlineInputBorder()),
          ),
          ElevatedButton(
            onPressed: _joined ? null : () async {
              await AgoraRtcEngine.joinChannel(null, _channelController.text, null, 0);
              setState(() => _joined = true);
            },
            child: Text('Join Call'),
          ),
          Expanded(
            child: Stack(
              children: [
                AgoraRtcEngine.createRendererView(context),
                if (_remoteUid != null) AgoraRtcEngine.createRendererView(context),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _joined ? () async {
              await AgoraRtcEngine.leaveChannel();
              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'status': 'offline'});
              setState(() => _joined = false);
            } : null,
            child: Text('Leave Call'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AgoraRtcEngine.destroy();
    FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'status': 'offline'});
    super.dispose();
  }
}

// Chat Screen
class ChatScreen extends StatefulWidget {
  final String doctorId;
  ChatScreen({required this.doctorId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  String _getChatId(String userId, String doctorId) => userId.compareTo(doctorId) < 0 ? '$userId-$doctorId' : '$doctorId-$userId';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final offlineProvider = Provider.of<OfflineProvider>(context);
    final chatId = _getChatId(user!.uid, widget.doctorId);

    return Scaffold(
      appBar: AppBar(title: Text('Chat with Doctor')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chats').doc(chatId).collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: offlineProvider.getCachedChats(chatId),
                    builder: (context, offlineSnapshot) {
                      if (!offlineSnapshot.hasData) return Center(child: CircularProgressIndicator());
                      final messages = offlineSnapshot.data!;
                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ListTile(title: Text(msg['text']), subtitle: Text(msg['sender'] + ' (Offline)'));
                        },
                      );
                    },
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    return ListTile(title: Text(msg['text']), subtitle: Text(msg['sender']));
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Type a message', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty) {
                      final message = {
                        'text': _messageController.text,
                        'sender': user.email,
                        'timestamp': FieldValue.serverTimestamp(),
                      };
                      try {
                        await _firestore.collection('chats').doc(chatId).collection('messages').add(message);
                        await _notifications.show(0, 'New Message', 'You have a new message!', NotificationDetails(android: AndroidNotificationDetails('channel_id', 'Messages')));
                      } catch (e) {
                        await offlineProvider.cacheChat(chatId, user.email!, _messageController.text);
                      }
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Appointment Screen
class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _firestore = FirebaseFirestore.instance;
  DateTime? _selectedDate;
  String? _selectedDoctor;

  Future<void> _scheduleReminder(DateTime date, String doctorId) async {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      await _notifications.zonedSchedule(
        date.hashCode,
        'Appointment Reminder',
        'Your appointment with $doctorId is tomorrow at ${DateFormat.Hm().format(date)}!',
        TZDateTime.from(date.subtract(Duration(hours: 24)), local),
        NotificationDetails(android: AndroidNotificationDetails('channel_id', 'Appointments')),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final offlineProvider = Provider.of<OfflineProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Book Appointment')),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('role', isEqualTo: 'doctor').where('status', isEqualTo: 'online').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final doctors = snapshot.data!.docs;
              return DropdownButton<String>(
                hint: Text('Select Doctor'),
                value: _selectedDoctor,
                items: doctors.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['email']))).toList(),
                onChanged: (value) => setState(() => _selectedDoctor = value),
              );
            },
          ),
          ElevatedButton(
            onPressed: () async {
              _selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 30)),
              );
              setState(() {});
            },
            child: Text(_selectedDate == null ? 'Select Date' : 'Date: ${_selectedDate!.toString().substring(0, 10)}'),
          ),
          ElevatedButton(
            onPressed: _selectedDate == null || _selectedDoctor == null
                ? null
                : () async {
                    final appt = {
                      'userId': user!.uid,
                      'doctorId': _selectedDoctor,
                      'date': _selectedDate!.toIso8601String(),
                      'status': 'pending',
                    };
                    try {
                      await _firestore.collection('appointments').add(appt);
                      await _notifications.show(0, 'Appointment Booked', 'Your appointment is set for ${_selectedDate!.toString().substring(0, 10)}', NotificationDetails(android: AndroidNotificationDetails('channel_id', 'Appointments')));
                      await _scheduleReminder(_selectedDate!, _selectedDoctor!);
                    } catch (e) {
                      await offlineProvider.cacheAppointment(user.uid, _selectedDoctor!, appt['date']!, appt['status']!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved offline!')));
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment booked!')));
                  },
            child: Text('Book Appointment'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('appointments').where('userId', isEqualTo: user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: offlineProvider.getCachedAppointments(user.uid),
                    builder: (context, offlineSnapshot) {
                      if (!offlineSnapshot.hasData) return Center(child: CircularProgressIndicator());
                      final appointments = offlineSnapshot.data!;
                      return ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appt = appointments[index];
                          return ListTile(
                            title: Text('Date: ${appt['date'].substring(0, 10)}'),
                            subtitle: Text('Status: ${appt['status']} (Offline)'),
                          );
                        },
                      );
                    },
                  );
                }
                final appointments = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Date: ${appt['date'].substring(0, 10)}'),
                      subtitle: Text('Status: ${appt['status']} - Doctor: ${appt['doctorId']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () async {
                              await _firestore.collection('appointments').doc(appointments[index].id).delete();
                              await _notifications.cancel(appt['date'].hashCode);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              final newDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.parse(appt['date']),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 30)),
                              );
                              if (newDate != null) {
                                await _firestore.collection('appointments').doc(appointments[index].id).update({'date': newDate.toIso8601String()});
                                await _scheduleReminder(newDate, appt['doctorId']);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Health Records Screen
class HealthRecordsScreen extends StatefulWidget {
  @override
  _HealthRecordsScreenState createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  String? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final offlineProvider = Provider.of<OfflineProvider>(context);
    final isDoctor = Provider.of<AuthProvider>(context).role == 'doctor';

    return Scaffold(
      appBar: AppBar(title: Text('Health Records')),
      body: Column(
        children: [
          if (isDoctor)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').where('role', isEqualTo: 'patient').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      final patients = snapshot.data!.docs;
                      return DropdownButton<String>(
                        hint: Text('Select Patient'),
                        value: _selectedPatient,
                        items: patients.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['email']))).toList(),
                        onChanged: (value) => setState(() => _selectedPatient = value),
                      );
                    },
                  ),
                  TextField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(labelText: 'Diagnosis', border: OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _prescriptionController,
                    decoration: InputDecoration(labelText: 'Prescription', border: OutlineInputBorder()),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_diagnosisController.text.isNotEmpty && _prescriptionController.text.isNotEmpty && _selectedPatient != null) {
                        final record = {
                          'patientId': _selectedPatient,
                          'diagnosis': _diagnosisController.text,
                          'prescription': _prescriptionController.text,
                          'doctor': user!.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        };
                        try {
                          await _firestore.collection('health_records').add(record);
                        } catch (e) {
                          await offlineProvider.cacheRecord(_selectedPatient!, record['diagnosis']!, record['prescription']!);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved offline!')));
                        }
                        _diagnosisController.clear();
                        _prescriptionController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Record added!')));
                      }
                    },
                    child: Text('Add Record'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('health_records').where('patientId', isEqualTo: user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: offlineProvider.getCachedRecords(user.uid),
                    builder: (context, offlineSnapshot) {
                      if (!offlineSnapshot.hasData) return Center(child: CircularProgressIndicator());
                      final records = offlineSnapshot.data!;
                      return ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            title: Text('Diagnosis: ${record['diagnosis']}'),
                            subtitle: Text('Prescription: ${record['prescription']} (Offline)'),
                          );
                        },
                      );
                    },
                  );
                }
                final records = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Diagnosis: ${record['diagnosis']}'),
                      subtitle: Text('Prescription: ${record['prescription']} - By: ${record['doctor']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Screen
class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await FirebaseFirestore.instance.collection('payments').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'amount': 500,
      'paymentId': response.paymentId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _notifications.show(0, 'Payment Successful', 'Payment of 500 INR completed!', NotificationDetails(android: AndroidNotificationDetails('channel_id', 'Payments')));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Successful: ${response.paymentId}')));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet: ${response.walletName}')));
  }

  void _openCheckout() {
    var options = {
      'key': 'YOUR_RAZORPAY_KEY',
      'amount': 50000,
      'name': 'Telehealth-TCD',
      'description': 'Consultation Fee',
      'prefill': {'contact': '1234567890', 'email': FirebaseAuth.instance.currentUser!.email},
    };
    _razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _openCheckout,
              child: Text('Pay with Razorpay (500 INR)'),
            ),
            SizedBox(height: 20),
            Text('Local Payment Gateways coming soon!'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

// Emergency Screen
class EmergencyScreen extends StatelessWidget {
  Future<void> _callEmergency() async {
    final url = 'tel:911';
    if (await canLaunch(url)) await launch(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emergency Services')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _callEmergency,
              child: Text('Call Emergency (911)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
            SizedBox(height: 20),
            Text('Hospital locator coming soon!'),
          ],
        ),
      ),
    );
  }
}

// Educational Content Screen
class EducationalContentScreen extends StatelessWidget {
  final List<Map<String, String>> _content = [
    {'title': 'Understanding Diabetes', 'body': 'Diabetes is a chronic condition...'},
    {'title': 'Healthy Eating Tips', 'body': 'A balanced diet includes...'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Learn More')),
      body: ListView.builder(
        itemCount: _content.length,
        itemBuilder: (context, index) {
          final item = _content[index];
          return ListTile(
            title: Text(item['title']!),
            subtitle: Text(item['body']!.substring(0, 50) + '...'),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(item['title']!),
                content: Text(item['body']!),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Admin Dashboard Screen
class AdminDashboardScreen extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(user['email']),
                      subtitle: Text('Role: ${user['role']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _firestore.collection('users').doc(users[index].id).delete(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('appointments').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final appointments = snapshot.data!.docs;
                final data = [
                  charts.Series<Map<String, dynamic>, String>(
                    id: 'Appointments',
                    domainFn: (appt, _) => DateFormat('MM/dd').format(DateTime.parse(appt['date'])),
                    measureFn: (appt, _) => 1,
                    data: appointments.map((doc) => doc.data() as Map<String, dynamic>).toList(),
                  ),
                ];
                return Container(
                  height: 200,
                  padding: EdgeInsets.all(16),
                  child: charts.BarChart(data, animate: true),
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('payments').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final total = snapshot.data!.docs.fold(0, (sum, doc) => sum + (doc['amount'] as int));
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Total Payments: $total INR', style: TextStyle(fontSize: 18)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Symptom Checker Screen
class SymptomCheckerScreen extends StatefulWidget {
  @override
  _SymptomCheckerScreenState createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _speech = stt.SpeechToText();
  String _symptoms = '';
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Symptom Checker')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Enter symptoms manually', border: OutlineInputBorder()),
              onChanged: (value) => setState(() => _symptoms = value),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!_isListening) {
                  bool available = await _speech.initialize();
                  if (available) {
                    setState(() => _isListening = true);
                    _speech.listen(onResult: (result) => setState(() => _symptoms = result.recognizedWords));
                  }
                } else {
                  setState(() => _isListening = false);
                  _speech.stop();
                }
              },
              child: Text(_isListening ? 'Stop Listening' : 'Speak Symptoms'),
            ),
            SizedBox(height: 20),
            Text('Symptoms: $_symptoms'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String response = _symptoms.toLowerCase().contains('fever') && _symptoms.toLowerCase().contains('cough') ? 'Possible Flu - Consult a doctor' : 'Symptoms unclear - Try again or consult a doctor';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response)));
              },
              child: Text('Check Symptoms'),
            ),
            SizedBox(height: 20),
            Text('Full AI integration coming soon!'),
          ],
        ),
      ),
    );
  }
}