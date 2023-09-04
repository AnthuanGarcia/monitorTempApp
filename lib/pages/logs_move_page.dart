import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
          //print(snapshot.error);
          return const Text("Error");
        }

        if (!snapshot.hasData) {
          return const Text("No data");
        }

        final docs = snapshot.data!.docs;
        //final indexes = docs.asMap().keys.toList();

        return PageView.builder(
          controller: _controller,
          itemCount: docs.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            List<int> date =
                docs[index].id.split("-").map((d) => int.parse(d)).toList();

            String title =
                "${Utils.weekDay(date[2], date[1], date[0])}, ${date[2]}/${date[1]}/${date[0]}";

            final logs = docs[index].data()["move_logs"] as List;

            return SingleChildScrollView(
              child: Column(
                //direction: Axis.vertical,
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  (logs.isEmpty || logs == null)
                      ? Container(
                          margin: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.4),
                          child: const Text(
                            "Sin lecturas de movimiento",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        )
                      : Container(
                          height: MediaQuery.of(context).size.height * .75,
                          margin: const EdgeInsets.all(18),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                child: Text(
                                  logs[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
