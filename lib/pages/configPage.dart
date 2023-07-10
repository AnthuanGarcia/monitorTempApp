import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Config extends StatefulWidget {
  const Config({super.key});

  @override
  State<Config> createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  DatabaseReference dbrt = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dbrt.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Text("ERROR");
        }

        if (!snapshot.hasData) {
          return Text("No data");
        }

        final config = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final ip = config["config"]["ip"] as String;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 80.0, horizontal: 16),
          child: Column(
            children: [
              Text(
                "Direccion IP:",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 10),
              Text(
                ip,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
