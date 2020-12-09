import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PushNotificationsManager    {
  PushNotificationsManager._();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings androidInitializationSettings;
  IOSInitializationSettings iosInitializationSettings;
  InitializationSettings initializationSettings;

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance =
  PushNotificationsManager._();

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure();

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("Device Token:---->$token");

      _initialized = true;

      handlePushNotificationEvents();
    }

    initializing();
  }

  @override
  void dispose() {
    _initialized = false;
    _firebaseMessaging = null;
  }

  void handlePushNotificationEvents() {
    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) async {
        print(message);
        _showNotifications(message["notification"]["title"], message["notification"]["body"]);
        //Add some navigation logic here
      },
      onResume: (Map<String, dynamic> message) async {
        print(message);
        _showNotifications(message["notification"]["title"], message["notification"]["body"]);
      },
      onMessage: (Map<String, dynamic> message) async {
        print(message);
        _showNotifications(message["notification"]["title"], message["notification"]["body"]);
      },
    );
  }

  void initializing() async{
    androidInitializationSettings = AndroidInitializationSettings('app_icon');
    iosInitializationSettings = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = InitializationSettings(android: androidInitializationSettings, iOS: iosInitializationSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);
  }

  void _showNotifications(String titulo, String mensaje) async{
    await notification(titulo, mensaje);
  }

  Future<void> notification(String titulo, String mensaje) async{
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'Channel ID',
        'Channel title',
        'Channel Body',
        priority: Priority.high,
        importance: Importance.max,
        ticker: 'test'
    );

    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, titulo, mensaje, notificationDetails);
  }

  Future onSelectNotification(String payLoad){
    if (payLoad != null){
      print (payLoad);
    }
  }

  Future onDidReceiveLocalNotification(int id, String title, String body, String payload) async{
    return CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: (){
                print("");
              },
              child: Text("Okay")),
        ]
    );
  }

}