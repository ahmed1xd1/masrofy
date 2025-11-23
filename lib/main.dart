import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    fln.FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications
  const fln.AndroidInitializationSettings initializationSettingsAndroid =
      fln.AndroidInitializationSettings('@mipmap/launcher_icon');
  final fln.InitializationSettings initializationSettings =
      fln.InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize Timezone
  tz_data.initializeTimeZones();

  // Schedule Daily Notification
  await _scheduleDailyNotification();

  // Check First Run
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  runApp(ExpenseTrackerApp(isFirstRun: isFirstRun));
}

Future<void> _scheduleDailyNotification() async {
  const fln.AndroidNotificationDetails androidNotificationDetails =
      fln.AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminder',
        channelDescription: 'Reminds you to log expenses daily',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
      );
  const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
    android: androidNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'تذكير يومي',
    'لا تنس تسجيل مصاريفك اليوم!',
    _nextInstanceOfNinePM(),
    notificationDetails,
    androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
  );
}

tz.TZDateTime _nextInstanceOfNinePM() {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    21,
  );
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

class ExpenseTrackerApp extends StatefulWidget {
  final bool isFirstRun;
  const ExpenseTrackerApp({super.key, required this.isFirstRun});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.cairoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
      ),
      themeMode: _themeMode,
      home: widget.isFirstRun
          ? OnboardingScreen(
              onThemeChanged: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
            )
          : MainScreen(
              onThemeChanged: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
            ),
    );
  }
}
