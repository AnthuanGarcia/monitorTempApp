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
import 'package:temp_monitor/src/palette.dart';
import 'package:temp_monitor/src/utils.dart';
import 'package:vector_math/vector_math.dart' as math;
//import 'package:vector_math/vector_math.dart';
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

  AnimationController? _animationControllerTemp, _animationControllerColPage;
  Animation<double>? _changeBackTemp, _changeBackPage;
  //math.Vector3 currentCol = math.Vector3.zero();
  Palette cols = Palette(
        primary: math.Vector3(.6941, .8353, 1.0),
        secondary: math.Vector3(0.9176, 0.5176, 1.0),
        main: math.Vector3(.1333, .5804, 1.0),
      ),
      colors = Palette(
        primary: math.Vector3(1.0, 0.5294, 0.0588),
        secondary: math.Vector3(0.949, 0.0431, 0.4824),
        main: math.Vector3(1.0, 0.6314, 0.2627),
      );

  final List<Widget> _pages = [
    MainPage(changeBackCol: () {}, undoBackCol: () {}),
    const LogsTemperature(),
    const LogsMovement(),
    const Config(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder()
  ];

  final grad = Shady(assetName: 'assets/shaders/heightCols.frag', uniforms: [
    UniformVec3(key: 'resolution', transformer: UniformVec3.resolution),
    UniformFloat(key: 'time', transformer: UniformFloat.secondsPassed),
    UniformFloat(key: 'temperature'),
    UniformFloat(key: 'colInt'),
    UniformVec3(key: 'priCol', initialValue: math.Vector3(.6941, .8353, 1.0)),
    UniformVec3(key: 'secCol', initialValue: math.Vector3(0.9176, 0.5176, 1.0)),
    UniformVec3(key: 'mainCol', initialValue: math.Vector3(.1333, .5804, 1.0)),
  ]);

  int _selectedIndex = 0;

  void setCol() {
    _animationControllerTemp!.forward();
  }

  void undoCol() {
    _animationControllerTemp!.reverse();
  }

  /*void changeColPage(Palette colors) {
  }*/

  @override
  void initState() {
    super.initState();

    _animationControllerTemp = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationControllerColPage = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _changeBackTemp = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationControllerTemp!);

    _changeBackTemp!.addListener(() {
      grad.setUniform<double>('temperature', _changeBackTemp!.value);
    });

    _changeBackPage = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationControllerColPage!);

    _controller.addListener(() {
      double size = _controller.viewportFraction / _pages.length.toDouble();
      double val = _controller.page!;

      cols.primary = Utils.lerp(
        cols.primary, colors.primary, val, //_changeBackPage!.value,
      );

      cols.secondary = Utils.lerp(
        cols.secondary, colors.secondary, val, //_changeBackPage!.value,
      );

      cols.main = Utils.lerp(
        cols.main, colors.main, val, //_changeBackPage!.value,
      );

      print("$val ${_controller.viewportFraction}");

      grad.setUniform<math.Vector3>("priCol", cols.primary);
      grad.setUniform<math.Vector3>("secCol", cols.secondary);
      grad.setUniform<math.Vector3>("mainCol", cols.main);
    });

    /*double sizePage =
        _controller.position.maxScrollExtent / _pages.length.toDouble();
    double? lastPage = _controller.page;

    _controller.addListener(() {
      double pos = _controller.offset / sizePage;
      double? currPage = _controller.page;

      if (lastPage! < currPage!) {
        pos -= sizePage;
      } else if (lastPage > currPage) {}
    });*/

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
    _animationControllerTemp!.dispose();
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
              onPageChanged: (page) {
                /*//_animationControllerColPage!.reset();
                  setState(() {
                    //while (!_animationControllerColPage!.isCompleted);
                    if (page == 1) {
                      changeColPage(Palette(
                        primary: math.Vector3(1.0, 0.5294, 0.0588),
                        secondary: math.Vector3(0.949, 0.0431, 0.4824),
                        main: math.Vector3(1.0, 0.6314, 0.2627),
                      ));
                    } else {
                      changeColPage(Palette(
                        primary: math.Vector3(1.0, 0.0, 0.0),
                        secondary: math.Vector3(0.0, 1, 0),
                        main: math.Vector3(0, 0, 1),
                      ));
                    }

                    //_animationControllerColPage!.forward();
                    //print(
                    //    "${_controller.offset}, ${_controller.position.minScrollExtent}");

                    
                  });*/
              },
            )),
          ],
        ),
      ),
    );
  }
}
