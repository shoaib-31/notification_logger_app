import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_logger_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(NotificationLoggerApp());
}

class NotificationLoggerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Logger App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationLoggerPage(),
    );
  }
}
