import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shady/shady.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temp_monitor/pages/configPage.dart';
import 'package:temp_monitor/pages/logsMovePage.dart';
import 'package:temp_monitor/pages/logsTempsPage.dart';
import 'package:temp_monitor/pages/mainPage.dart';
//import 'package:temp_monitor/src/shader_painter.dart';
//import 'package:flutter_shaders/flutter_shaders.dart';

//const serverHost = "192.168.1.168:8080";

const channel = AndroidNotificationChannel(
  'temp_monitor', // id
  'Temperature Monitor', // title
  //groupId: "ambient_alerts",
  description: 'Get temperature in real time', // description
  importance: Importance.max,
);

bool isFlutterLocalNotificationsInitialized = false;

//late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

  /*
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();*/

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
      debugShowCheckedModeBanner: false,
      //showPerformanceOverlay: true,
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

class _MonitorPageState extends State<MonitorPage>
    with TickerProviderStateMixin {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final PageController _controller = PageController();

  final grad = Shady(assetName: 'assets/shaders/heightCols.frag', uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
    UniformFloat(key: 'temperature'),
    UniformFloat(key: 'histBack')
  ]);

  AnimationController? _animationController, _animationControllerHist;
  Animation<double>? _changeBack, _changeBackHist;

  int _selectedIndex = 0;

  void setCol() {
    _animationController!.forward();
  }

  void undoCol() {
    _animationController!.reverse();
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationControllerHist = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _changeBack = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController!);

    _changeBack!.addListener(() {
      grad.setUniform<double>('temperature', _changeBack!.value);
    });

    _changeBackHist = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationControllerHist!);

    _changeBackHist!.addListener(() {
      grad.setUniform<double>('histBack', _changeBackHist!.value);
    });

    FirebaseAuth auth = FirebaseAuth.instance;

    SharedPreferences.getInstance().then((prefs) {
      String? idUser = prefs.getString("user_id");
      if (idUser == null ||
          auth.currentUser == null ||
          idUser != auth.currentUser?.uid) {
        auth.signInAnonymously().then((data) {
          prefs.setString("user_id", data.user!.uid);

          messaging.getToken().then((token) {
            FirebaseFirestore.instance
                .collection("tokens")
                .add(<String, dynamic>{
              "token": token!,
              "created_at": DateTime.now().toIso8601String()
            });
          });
          setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _animationController!.dispose();
    _animationControllerHist!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            SizedBox.expand(
              child: ShadyCanvas(grad),
            ),
            Center(
              child: PageView(
                scrollDirection: Axis.vertical,
                controller: _controller,
                children: [
                  MainPage(changeBackCol: setCol, undoBackCol: undoCol),
                  const LogsTemperature(),
                  const LogsMovement(),
                  const Config(),
                ],
                onPageChanged: (page) {
                  setState(() {
                    if (page == 1) {
                      _animationControllerHist!.forward();
                    } else {
                      _animationControllerHist!.reverse();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
