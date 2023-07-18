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
  List<bool> shit = List.generate(7, (index) => false);

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

        // TO DO
        // - Replace the map func for mapDocs to indexes list :'v
        return Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * .075),
          child: SingleChildScrollView(
            child: ExpansionPanelList(
              elevation: 0,
              dividerColor: Colors.transparent,
              expansionCallback: (idx, isExpanded) {
                setState(() {
                  shit[idx] = !isExpanded;
                });
              },
              children: indexes.map(
                (i) {
                  //final doc = mapDocs[i];
                  final logs = mapDocs[i].data.data()["move_logs"] as List;
                  print(logs);

                  return ExpansionPanel(
                    backgroundColor: Colors.transparent,
                    headerBuilder: (context, isExpanded) {
                      List<int> date = mapDocs[i]
                          .data
                          .id
                          .split("-")
                          .map((d) => int.parse(d))
                          .toList();

                      String title =
                          "${Utils.weekDay(date[0], date[1], date[2])}, ${date[0]} de ${Utils.months[date[1] - 1]} del ${date[2]}";

                      return ListTile(
                          title: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ));
                    },
                    body: ListView.builder(
                      clipBehavior: Clip.none,
                      shrinkWrap: true,
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            logs[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      },
                    ),
                    isExpanded: shit[i],
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }
}
