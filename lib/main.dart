import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shady/shady.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temp_monitor/pages/config_page.dart';
import 'package:temp_monitor/pages/logs_move_page.dart';
import 'package:temp_monitor/pages/logs_temps_page.dart';
import 'package:temp_monitor/pages/main_page.dart';
import 'package:temp_monitor/src/ambient.dart';
import 'package:temp_monitor/src/palette.dart';
import 'package:temp_monitor/src/utils.dart';
import 'package:vector_math/vector_math.dart' as math;

//const serverHost = "192.168.1.168:8080";

const channel = AndroidNotificationChannel(
  'temp_monitor', // id
  'Temperature Monitor', // title
  //groupId: "ambient_alerts",
  description: 'Get temperature in real time', // description
  importance: Importance.max,
);

bool isFlutterLocalNotificationsInitialized = false;
const temperatureAlert = 22;

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
  //print('Handling a background message ${message.messageId}');
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
  final data = message.data;
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
  DatabaseReference dbrt = FirebaseDatabase.instance.ref();

  final PageController _controller = PageController();

  AnimationController? /*_animationControllerTemp,*/
      _animationControllerColPage;
  Animation<double>? /*_changeBackTemp,*/ _changeBackPage;
  late Palette cols = Palette(
    primary: math.Vector3(.6941, .8353, 1.0),
    secondary: math.Vector3(0.9176, 0.5176, 1.0),
    main: math.Vector3(.1333, .5804, 1.0),
  );

  final List<Widget> _pages = [
    const MainPage(),
    const LogsTemperature(),
    const LogsMovement(),
    const Config(),
  ];

  final grad = Shady(assetName: 'assets/shaders/heightCols.frag', uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
    //UniformFloat(key: 'temperature'),
    UniformFloat(key: 'colInt'),
    UniformVec3(key: 'priCol', initialValue: math.Vector3(.6941, .8353, 1.0)),
    UniformVec3(key: 'secCol', initialValue: math.Vector3(0.9176, 0.5176, 1.0)),
    UniformVec3(key: 'mainCol', initialValue: math.Vector3(.1333, .5804, 1.0)),
  ]);

  @override
  void initState() {
    super.initState();

    _animationControllerColPage = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _changeBackPage = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationControllerColPage!);

    _changeBackPage?.addListener(() {
      cols.primary = Utils.lerp(
        math.Vector3(.6941, .8353, 1.0),
        math.Vector3(1.0, 0.6941, 0.6941),
        _changeBackPage!.value,
      );

      cols.secondary = Utils.lerp(
        math.Vector3(0.9176, 0.5176, 1.0),
        math.Vector3(0.9922, 0.8039, 0.3961),
        _changeBackPage!.value,
      );

      cols.main = Utils.lerp(
        math.Vector3(.1333, .5804, 1.0),
        math.Vector3(1.0, 0.1333, 0.1333),
        _changeBackPage!.value,
      );

      grad.setUniform<math.Vector3>("priCol", cols.primary);
      grad.setUniform<math.Vector3>("secCol", cols.secondary);
      grad.setUniform<math.Vector3>("mainCol", cols.main);
    });

    dbrt.onValue.listen((data) {
      final ambient =
          Ambient.fromDbSnap(data.snapshot.value as Map<Object?, Object?>);

      if (ambient.temperature.toInt() > temperatureAlert) {
        _animationControllerColPage!.forward();
      } else {
        _animationControllerColPage!.reverse();
      }
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
    super.dispose();
    _animationControllerColPage!.dispose();
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
                children: _pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
