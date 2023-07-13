import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:temp_monitor/src/item.dart';

class LogsMovement extends StatefulWidget {
  const LogsMovement({super.key});

  @override
  State<LogsMovement> createState() => _LogsMovementState();
}

class _LogsMovementState extends State<LogsMovement> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: Container(
          child: StreamBuilder(
            stream: _db.collection("movement").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Error");
              }

              final mapDocs =
                  snapshot.data!.docs.map((e) => Item(data: e)) as List<Item>;

              return ExpansionPanelList(
                expansionCallback: (idx, isExpanded) => setState(() {
                  mapDocs[idx].isExpanded = !isExpanded;
                }),
                children: mapDocs
                    .map(
                      (doc) => ExpansionPanel(
                        headerBuilder: (context, isExpanded) {
                          return ListTile(title: Text(""));
                        },
                        body: Placeholder(),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
