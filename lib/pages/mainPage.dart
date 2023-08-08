import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:countup/countup.dart';
import 'package:firebase_database/firebase_database.dart';
import '../src/ambient.dart';

const temperatureAlert = 22;

typedef BackCallback = void Function();

class MainPage extends StatefulWidget {
  MainPage({super.key, required this.changeBackCol, required this.undoBackCol});

  BackCallback changeBackCol, undoBackCol;

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DatabaseReference dbrt = FirebaseDatabase.instance.ref();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  Ambient? prevAmbient, ambient;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: StreamBuilder(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: Text(
                "Cargando...",
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                ),
              ),
            );
          }

          ambient ??= const Ambient();
          prevAmbient = ambient;

          ambient = Ambient.fromDbSnap(
              snap.data!.snapshot.value as Map<Object?, Object?>);

          if (ambient!.temperature.toInt() > temperatureAlert) {
            //_controller!.forward();
            widget.changeBackCol();
          } else {
            //_controller!.reverse();
            widget.undoBackCol();
          }

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
                                  image: AssetImage('assets/imgs/warning.png'),
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
                                begin: prevAmbient!.temperature.toDouble(),
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
    );
  }
}
