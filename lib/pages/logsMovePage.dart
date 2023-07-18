import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:temp_monitor/src/item.dart';
import 'package:temp_monitor/src/utils.dart';

class LogsMovement extends StatefulWidget {
  const LogsMovement({super.key});

  @override
  State<LogsMovement> createState() => _LogsMovementState();
}

class _LogsMovementState extends State<LogsMovement> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PageController _controller =
      PageController(initialPage: DateTime.now().weekday - 1);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.collection("movement").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Text("Error");
        }

        if (!snapshot.hasData) {
          return Text("No data");
        }

        final mapDocs = snapshot.data!.docs.map((e) => Item(data: e)).toList();
        final indexes = mapDocs.asMap().keys.toList();

        return PageView.builder(
          controller: _controller,
          itemCount: Utils.weekDays.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.25),
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                child: Text(
                  Utils.weekDays[index],
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
