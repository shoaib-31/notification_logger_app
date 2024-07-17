import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class NotificationLoggerPage extends StatefulWidget {
  @override
  _NotificationLoggerPageState createState() => _NotificationLoggerPageState();
}

class _NotificationLoggerPageState extends State<NotificationLoggerPage> {
  bool _permissionGranted = false;
  bool _isListenerRegistered = false; // Flag to track listener registration
  List<Map<String, String>> _notifications = [];
  Map<String, dynamic> _mostPlayedNotification = {
    'title': 'No title',
    'content': 'No content'
  };

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getMostPlayedNotification();
  }

  Future<void> _checkPermission() async {
    final status = await NotificationListenerService.isPermissionGranted();
    setState(() {
      _permissionGranted = status;
    });
    if (!status) {
      _requestPermission();
    } else {
      _listenToNotifications();
    }
  }

  Future<void> _requestPermission() async {
    final status = await NotificationListenerService.requestPermission();
    setState(() {
      _permissionGranted = status;
    });
    if (status) {
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    if (!_isListenerRegistered) {
      NotificationListenerService.notificationsStream.listen((event) {
        if (_isSpotifyNotification(event)) {
          final title = event.title ?? 'No title';
          final content = event.content ?? 'No content';
          final newNotification = {'title': title, 'content': content};

          print('Received notification: $newNotification');
          _addOrUpdateNotification(newNotification);
        }
      });
      _isListenerRegistered = true; // Mark listener as registered
    }
  }

  bool _isSpotifyNotification(dynamic event) {
    // Check if the notification is from Spotify
    return event.packageName == 'com.spotify.music';
  }

  void _addOrUpdateNotification(Map<String, String> notification) {
    setState(() {
      if (_notifications.isEmpty ||
          _notifications.last['title'] != notification['title'] ||
          _notifications.last['content'] != notification['content']) {
        _notifications.add(notification);
        _insertNotificationToFirestore(notification);
      }
    });
  }

  Future<void> _insertNotificationToFirestore(
      Map<String, String> notification) async {
    final firestore = FirebaseFirestore.instance;
    final docRef =
        firestore.collection('notifications').doc(notification['title']);

    await firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        final newCount = doc['count'] + 1;
        transaction.update(docRef, {'count': newCount});
        print(
            'Updated notification count: ${notification['title']} to $newCount');
      } else {
        transaction.set(docRef, {
          'title': notification['title'],
          'content': notification['content'],
          'count': 1
        });
        print('Inserted new notification: $notification');
      }
    });

    _getMostPlayedNotification(); // Refresh most played notification
  }

  Future<void> _getMostPlayedNotification() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('notifications')
        .orderBy('count', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _mostPlayedNotification = querySnapshot.docs.first.data();
        print('Fetched most played notification: $_mostPlayedNotification');
      });
    } else {
      setState(() {
        _mostPlayedNotification = {
          'title': 'No title',
          'content': 'No content'
        };
      });
      print('No notifications found in Firestore.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Logger'),
      ),
      body: _permissionGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Most Played Song',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _mostPlayedNotification['title'] ?? 'No title',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _mostPlayedNotification['content'] ?? 'No content',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Center(
              child: ElevatedButton(
                onPressed: _requestPermission,
                child: Text('Request Permission'),
              ),
            ),
    );
  }
}
