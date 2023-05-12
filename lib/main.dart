import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:countup/countup.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shady/shady.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temp_monitor/src/shader_painter.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import './src/ambient.dart';

const serverHost = "192.168.1.168:8080";
//const serverHost = "push-alerts.onrender.com";

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

class _MonitorPageState extends State<MonitorPage> {
  //final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  DatabaseReference db = FirebaseDatabase.instance.ref();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late Ambient? prevAmbient, ambient;

  //FragmentShader? shader;
  //Duration previous = Duration.zero;
  //late final Ticker _ticker;
  //double dt = 0.0;

  /*final glowRing = Shady(assetName: "shaders/test.frag", uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
    UniformFloat(key: 'radius', initialValue: 0.35),
    UniformVec2(key: 'position'),
  ]);*/

  final grad = Shady(assetName: 'shaders/heightCols.frag', uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
  ]);

  @override
  void initState() {
    super.initState();

    //FirebaseMessaging.onMessage.listen(showFlutterNotification);

    //_ticker = Ticker(_tick);
    //_ticker.start();

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
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            SizedBox.expand(
              child: ShadyCanvas(grad),
            ),
            StreamBuilder(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Text("Cargando...");
                }

                prevAmbient ??= const Ambient();
                prevAmbient = ambient;

                ambient = Ambient.fromDbSnap(
                    snap.data!.snapshot.value as Map<Object?, Object?>);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //padding: const EdgeInsets.only(bottoqm: 100),
                      ambient!.movement == 0
                          ? const Text(
                              "No hay lecturas de movimiento",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            )
                          : Container(
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text("Hoal"),
                            ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20.0, 20, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Countup(
                                  begin: prevAmbient!.temperature.toDouble(),
                                  end: ambient!.temperature.toDouble(),
                                  duration: const Duration(seconds: 2),
                                  separator: ".",
                                  style: const TextStyle(
                                    fontSize: 72,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Text(
                                  "°C",
                                  style: TextStyle(
                                    fontSize: 72,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                )
                              ],
                            ),
                            const Text(
                              "Temperatura",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Countup(
                                      begin: prevAmbient!.humidity.toDouble(),
                                      end: ambient!.humidity.toDouble(),
                                      duration: const Duration(seconds: 2),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const Text(
                                      "%",
                                      style: TextStyle(
                                        fontSize: 48,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    )
                                  ],
                                ),
                                const Text(
                                  "Humedad",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                )
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Countup(
                                      begin: prevAmbient!.temperature
                                          .toDouble()
                                          .ceilToDouble(),
                                      end: ambient!.heatIndex
                                          .toDouble()
                                          .ceilToDouble(),
                                      duration: const Duration(seconds: 2),
                                      separator: ".",
                                      style: const TextStyle(
                                        fontSize: 48,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const Text(
                                      "°C",
                                      style: TextStyle(
                                        fontSize: 48,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    )
                                  ],
                                ),
                                const Text(
                                  "Indice de Calor",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
