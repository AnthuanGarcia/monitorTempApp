import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:temp_monitor/src/item.dart';
import 'package:temp_monitor/src/utils.dart';

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
              final indexes = mapDocs.asMap().keys.toList();

              // TO DO
              // - Replace the map func for mapDocs to indexes list :'v
              return ExpansionPanelList(
                expansionCallback: (idx, isExpanded) => setState(() {
                  mapDocs[idx].isExpanded = !isExpanded;
                }),
                children: indexes.map(
                  (i) {
                    return ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        String idDoc = mapDocs[i].data.id;
                        List<int> date =
                            idDoc.split("-").map((d) => int.parse(d)).toList();

                        String title =
                            "${Utils.weekDay(date[0], date[1], date[2])}, ${date[0]} de ${Utils.months[date[1]]} del ${date[2]}";

                        return ListTile(title: Text(title));
                      },
                      body: ListView.builder(
                        itemCount: (mapDocs[i].data.data()["move_logs"] as List)
                            .length,
                        itemBuilder: (ctx, idx) {
                          //final logs = ;
                          return Text("");
                        },
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
