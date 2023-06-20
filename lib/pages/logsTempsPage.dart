import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LogsTemperature extends StatefulWidget {
  const LogsTemperature({super.key});

  @override
  State<LogsTemperature> createState() => _LogsTemperatureState();
}

class _LogsTemperatureState extends State<LogsTemperature> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: db.collection("temperatures").doc("values").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("------------->${snapshot.error}");
          return const Text("Error");
        }

        if (!snapshot.hasData) {
          return const Text("No data");
        }

        final data = snapshot.data!.data();
        final temps =
            (data!["Values"] as List).map((val) => val as double).toList();

        return AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
            child: LineChart(
              LineChartData(
                minX: 0.0,
                maxX: 24.0,
                minY: 17.0,
                maxY: 50.0,
                lineBarsData: [
                  LineChartBarData(
                    spots: [],
                    isCurved: true,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
