import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './src/ambient.dart';

//const serverHost = "10.9.9.115:8080";
const serverHost = "192.168.1.168:8080";

const channel = AndroidNotificationChannel(
  'temp_monitor', // id
  'Temperature Monitor', // title
  //groupId: "ambient_alerts",
  description: 'Get temperature in real time', // description
  importance: Importance.high,
);

const group = AndroidNotificationChannelGroup("temp_monitor_group", "alerts");

bool isFlutterLocalNotificationsInitialized = false;

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  prefs = await SharedPreferences.getInstance();
  runApp(const MonitorTemp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  showFlutterNotification(message);
  print('Handling a background message ${message.messageId}');
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  //RemoteNotification? notification = message.notification;
  //AndroidNotification? android = message.notification?.android;
  final data = message.data;
  //if (notification != null && android != null) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  flutterLocalNotificationsPlugin.getActiveNotifications().then(
    (notifications) {
      if (notifications.length >= 2) {
        return;
      }

      if (notifications.isNotEmpty &&
          data.containsKey(notifications.first.tag)) {
        return;
      }

      flutterLocalNotificationsPlugin.show(
        data.hashCode,
        data["Title"],
        null,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            tag: data.containsKey("Temp") ? "Temp" : "Move",
            channelDescription: channel.description,
            channelAction: AndroidNotificationChannelAction.update,
            groupAlertBehavior: GroupAlertBehavior.children,
            styleInformation: BigTextStyleInformation(
              data["Body"],
              htmlFormatBigText: true,
              htmlFormatContent: true,
            ),
            icon: 'launch_background',
            color: Colors.redAccent,
            colorized: true,
            onlyAlertOnce: true,
          ),
        ),
      );
    },
  );

  //}
}

class MonitorTemp extends StatelessWidget {
  const MonitorTemp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MonitorPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key, required this.title});

  final String title;

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  //final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  DatabaseReference db = FirebaseDatabase.instance.ref();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();

    //FirebaseMessaging.onMessage.listen(showFlutterNotification);

    final token = prefs.getString("user_token");
    if (token != null) return;

    print("No deberia llegar hasta aqui");

    messaging.getToken().then(
      (token) {
        http
            .post(
              Uri.http(
                serverHost,
                '/registerToken',
                {'token': token},
              ),
            )
            .then((res) => print("${res.statusCode}, ${res.body}"));

        prefs.setString("user_token", token!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Stream<DatabaseEvent> stream = db.onValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: StreamBuilder(
          stream: stream,
          builder: (context, snap) {
            List<Widget> children = <Widget>[const Text("Nada")];

            if (snap.hasData) {
              Ambient data = Ambient.fromDbSnap(
                  snap.data!.snapshot.value as Map<Object?, Object?>);

              children = <Widget>[
                Text("Temperature: ${data.temperature}"),
                Text("Humidity: ${data.humidity}"),
                Text("Heat Index: ${data.heatIndex}"),
                Text("Movement: ${data.movement}"),
              ];
            }

            return Column(children: children);
          },
        ),
      ),
    );
  }
}
