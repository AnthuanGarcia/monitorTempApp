import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import './src/ambient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

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
  String d = "";

  DatabaseReference db = FirebaseDatabase.instance.ref();

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
              //Ambient data = Ambient.fromDbSnap(
              //    snap.data!.snapshot.value as Map<Object?, Object?>);

              dynamic data = snap.data!.snapshot.value;

              children = <Widget>[
                Text("Temperature: ${data["test"]["temperature"]}"),
                Text("Humidity: ${data["test"]["humidity"]}"),
                Text("Heat Index: ${data["test"]["heatIndex"]}"),
                Text("Movement: ${data["test"]["move"]}"),
              ];
            }

            return Column(children: children);
          },
        ),
      ),
    );
  }
}
