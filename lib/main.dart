import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
//import 'package:workmanager/workmanager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import './src/ambient.dart';

/*const channel = AndroidNotificationChannel(
  'temp_monitor', // id
  'Temperature Monitor', // title
  description: 'Channel for monitoring temperature in site', // description
  importance: Importance.low, // importance must be at low or higher level
);*/

/*@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  showFlutterNotification(message);

  print("Handling a background message: ${message.messageId}");
}*/

const monitorTask = "monitor-temp";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //await AndroidAlarmManager.initialize();
  //await setupFlutterNotifications();
  await initializeService();
  /*await AndroidAlarmManager.periodic(
    const Duration(seconds: 15),
    8698,
    temperatureAlert,
    rescheduleOnReboot: true,
  );*/
  runApp(const MyApp());
}

/*@pragma('vm:entry-point')
void temperatureAlert() async {
  final data = await http.get(
    Uri.parse(
      "https://sockettemp-79575-default-rtdb.firebaseio.com/test.json?",
    ),
  );

  Ambient ambient =
      Ambient.fromJson(json.decode(data.body) as Map<String, dynamic>);

  if (ambient.humidity >= 50) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    String details =
        "Temperatura: ${ambient.temperature}°C<br>Humedad: ${ambient.humidity}%<br>Índice de calor: ${ambient.heatIndex.toStringAsFixed(2)}°C";

    flutterLocalNotificationsPlugin.show(
      8698,
      "Alerta de Temperatura",
      "",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: 'ic_bg_service_small',
          styleInformation: BigTextStyleInformation(
            details,
            htmlFormatBigText: true,
            htmlFormatContent: true,
          ),
        ),
      ),
    );
  }
}*/

/*Future<void> setupFlutterNotifications() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}*/

/*
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print(
        "Native called background task: $task"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}*/

Future<void> initializeService() async {
  await AwesomeNotifications().initialize(
    null, //'resource://drawable/res_app_icon',//
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Notification tests as alerts',
        playSound: true,
        onlyAlertOnce: true,
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Public,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.deepPurple,
      )
    ],
    debug: true,
  );

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'alerts',
      initialNotificationTitle: 'Obteniendo Temperatura',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await Firebase.initializeApp();
  DartPluginRegistrant.ensureInitialized();

  final notification = AwesomeNotifications();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  //DatabaseReference db = FirebaseDatabase.instance.ref();
  //bool onlyOne = false;

  /*db.onValue.listen((event) async {
    Ambient ambient =
        Ambient.fromDbSnap(event.snapshot.value as Map<Object?, Object?>);

    /*if (ambient.humidity > 50) {
      onlyOne = false;
      return
    }

    if (onlyOne) {
      return;
    }

    onlyOne = true;*/

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'Temperatura: ${ambient.temperature}',
          'Humedad: ${ambient.humidity}\nÍndice de calor: ${ambient.heatIndex}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: 'ic_bg_service_small',
              ongoing: false,
            ),
          ),
        );
      }

      service.invoke(
        'update',
        {
          "current_temp": ambient.temperature,
        },
      );
    }
  });*/

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    final data = await http.get(
      Uri.parse(
          "https://sockettemp-79575-default-rtdb.firebaseio.com/test.json?"),
    );

    Ambient ambient =
        Ambient.fromJson(json.decode(data.body) as Map<String, dynamic>);

    String details =
        "Humedad: ${ambient.humidity}%<br>Índice de calor: ${ambient.heatIndex.toStringAsFixed(2)}°C";

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        notification.createNotification(
          content: NotificationContent(
            id: 888,
            channelKey: 'alerts',
            title: 'Prueba',
            body: details,
          ),
        );
        //}
      }

      service.invoke(
        'update',
        {
          "current_temp": ambient.temperature,
        },
      );
    }
  });
}

/*Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }

  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'launch_background',
        ),
      ),
    );
  }
}
*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference db = FirebaseDatabase.instance.ref();
  String d = "";

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
