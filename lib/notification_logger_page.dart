import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class NotificationLoggerPage extends StatefulWidget {
  @override
  _NotificationLoggerPageState createState() => _NotificationLoggerPageState();
}

class _NotificationLoggerPageState extends State<NotificationLoggerPage> {
  bool _permissionGranted = false;
  bool _isListenerRegistered = false; // Flag to track listener registration
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
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
        final title = event.title ?? 'No title';
        final content = event.content ?? 'No content';
        final newNotification = {'title': title, 'content': content};

        setState(() {
          if (_notifications.isEmpty ||
              _notifications.last['title'] != newNotification['title'] ||
              _notifications.last['content'] != newNotification['content']) {
            _notifications.add(newNotification);
          }
        });
      });
      _isListenerRegistered = true; // Mark listener as registered
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Logger'),
      ),
      body: _permissionGranted
          ? ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_notifications[index]['title'] ?? 'No title'),
                  subtitle:
                      Text(_notifications[index]['content'] ?? 'No content'),
                );
              },
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
