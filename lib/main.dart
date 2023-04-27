import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  importance: Importance.high, // importance must be at low or higher level
);*/

//const monitorTask = "monitor-temp";

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool isFlutterLocalNotificationsInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  showFlutterNotification(message);
  print('Handling a background message ${message.messageId}');
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }

  channel = const AndroidNotificationChannel(
    'temp_monitor', // id
    'Temperature Monitor', // title
    description: 'Get temperature in real time', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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

/*@pragma('vm:entry-point')
void monitorTemp() async {
  /*final data = await http.get(
    Uri.parse(
      "https://sockettemp-79575-default-rtdb.firebaseio.com/test.json?",
    ),
  );

  Ambient ambient = Ambient.fromJson(
    json.decode(data.body) as Map<String, dynamic>,
  );*/

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const channel = AndroidNotificationChannel(
    'temp_monitor',
    'Temperature Monitor', // title
    description: 'Channel for monitoring temperature in site', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  flutterLocalNotificationsPlugin.show(
    8698,
    "Hola",
    "",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'temp_monitor',
        'Temperature Monitor',
      ),
    ),
  );
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

/*Future<void> initializeServices() async {
  await configService(
    const AndroidNotificationChannel(
      'temp_monitor_fore',
      'Foreground Monitor',
      importance: Importance.low,
    ),
    onStartFore,
    id: 1234,
    title: "Temperature Monitor",
    initCont: "Init",
    foreground: true,
  );

  await configService(
    const AndroidNotificationChannel(
      'temp_monitor_alert',
      'Alert Monitor',
      importance: Importance.high,
    ),
    onStartAlert,
    id: 5678,
    title: "Alert Monitor",
    foreground: false,
  );
}

Future<void> configService(
  AndroidNotificationChannel channel,
  dynamic Function(ServiceInstance) callback, {
  required int id,
  String title = "",
  String initCont = "",
  bool foreground = false,
}) async {
  final service = FlutterBackgroundService();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: callback,

      // auto start service
      autoStart: true,
      isForegroundMode: foreground,

      notificationChannelId: channel.id,
      initialNotificationTitle: title,
      initialNotificationContent: initCont,
      foregroundServiceNotificationId: id,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStartFore(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final data = await http.get(
          Uri.parse(
            "https://sockettemp-79575-default-rtdb.firebaseio.com/test.json?",
          ),
        );

        Ambient ambient =
            Ambient.fromJson(json.decode(data.body) as Map<String, dynamic>);

        String details =
            "Humedad: ${ambient.humidity}%<br>Índice de calor: ${ambient.heatIndex.toStringAsFixed(2)}°C";

        flutterLocalNotificationsPlugin.show(
          1234,
          'Temperatura: ${ambient.temperature}°C',
          "",
          NotificationDetails(
            android: AndroidNotificationDetails(
              'temp_monitor_fore',
              'Foreground Monitor',
              icon: 'ic_bg_service_small',
              ongoing: false,
              styleInformation: BigTextStyleInformation(
                details,
                htmlFormatBigText: true,
                htmlFormatContent: true,
              ),
            ),
          ),
        );
      }
    }
  });
}

@pragma('vm:entry-point')
void onStartAlert(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  Timer.periodic(
    const Duration(seconds: 30),
    (timer) async {
      if (service is AndroidServiceInstance) {
        final data = await http.get(
          Uri.parse(
            "https://sockettemp-79575-default-rtdb.firebaseio.com/test.json?",
          ),
        );

        Ambient ambient =
            Ambient.fromJson(json.decode(data.body) as Map<String, dynamic>);

        if (ambient.humidity <= 50) return;

        String details =
            "Humedad: ${ambient.humidity}%<br>Índice de calor: ${ambient.heatIndex.toStringAsFixed(2)}°C";

        flutterLocalNotificationsPlugin.show(
          5678,
          'Alerta de Temperatura: ${ambient.temperature}°C',
          "",
          NotificationDetails(
            android: AndroidNotificationDetails(
              'temp_monitor_alert',
              'Alert Monitor',
              icon: 'ic_bg_service_small',
              ongoing: false,
              styleInformation: BigTextStyleInformation(
                details,
                htmlFormatBigText: true,
                htmlFormatContent: true,
              ),
            ),
          ),
        );
      }
    },
  );
}*/

/*@pragma('vm:entry-point')
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
}*/

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
