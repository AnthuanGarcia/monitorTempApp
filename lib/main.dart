import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:countup/countup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shady/shady.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:temp_monitor/src/shader_painter.dart';
//import 'package:flutter_shaders/flutter_shaders.dart';
import './src/ambient.dart';

//const serverHost = "192.168.1.168:8080";

const channel = AndroidNotificationChannel(
  'temp_monitor', // id
  'Temperature Monitor', // title
  //groupId: "ambient_alerts",
  description: 'Get temperature in real time', // description
  importance: Importance.max,
);

const temperatureAlert = 22;

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
    with SingleTickerProviderStateMixin {
  //final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  DatabaseReference dbrt = FirebaseDatabase.instance.ref();
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  Ambient? prevAmbient, ambient;

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

  final grad = Shady(assetName: 'assets/shaders/heightCols.frag', uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
    UniformFloat(key: 'temperature'),
  ]);

  AnimationController? _controller;
  Animation<double>? _changeBack;

  @override
  void initState() {
    super.initState();

    //FirebaseMessaging.onMessage.listen(showFlutterNotification);

    //_ticker = Ticker(_tick);
    //_ticker.start();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _changeBack = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller!);

    _changeBack!.addListener(() {
      grad.setUniform<double>('temperature', _changeBack!.value);
    });

    final token = prefs.getString("user_token");
    if (token != null) return;

    print("No deberia llegar hasta aqui");

    messaging.getToken().then(
      (token) {
        FirebaseAuth.instance.signInAnonymously().then((value) {
          db.collection("tokens").add(<String, dynamic>{
            "token": token!,
            "created_at": DateTime.now().toIso8601String()
          });

          prefs.setString("user_token", token);
        });
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller!.dispose();
  }

  bool _fetching = false;
  bool _acceptedPermissions = false;

  Future<void> requestPermissions() async {
    setState(() {
      _fetching = true;
    });

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      criticalAlert: true,
      sound: true,
    );

    setState(() {
      _fetching = false;
      _acceptedPermissions =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  @override
  Widget build(BuildContext context) {
    Stream<DatabaseEvent> stream = dbrt.onValue;

    if (_fetching) {
      return const CircularProgressIndicator();
    }

    if (!_acceptedPermissions) {
      requestPermissions();
      return const Text("Acepta Los permisos");
    }

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

                //prevAmbient ??= const Ambient();
                ambient ??= const Ambient();
                prevAmbient = ambient;

                ambient = Ambient.fromDbSnap(
                    snap.data!.snapshot.value as Map<Object?, Object?>);

                if (ambient!.temperature.toInt() > temperatureAlert) {
                  _controller!.forward();
                } else {
                  _controller!.reverse();
                }

                //if (ambient!.temperature.toInt() <= 19) _controller!.reverse();

                return Center(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 160),
                        child: ambient!.movement < 1
                            ? const Text(
                                "No hay lecturas de movimiento",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  child: Wrap(
                                    children: const [
                                      Image(
                                        image: AssetImage(
                                            'assets/imgs/warning.png'),
                                        fit: BoxFit.fitHeight,
                                        height: 20,
                                        width: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "¡Movimiento detectado!",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(20.0, 20, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Countup(
                                      begin:
                                          prevAmbient!.temperature.toDouble(),
                                      end: ambient!.temperature.toDouble(),
                                      duration: const Duration(seconds: 2),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Countup(
                                          begin:
                                              prevAmbient!.humidity.toDouble(),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Countup(
                                          begin: prevAmbient!.heatIndex
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
