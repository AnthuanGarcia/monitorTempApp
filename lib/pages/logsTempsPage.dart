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

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.white);
    String text = value.toInt().toString();
    return Text(text, style: style);
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.white);
    String amPm = "AM";
    int hour = value.toInt();

    if (hour >= 12) {
      amPm = "PM";
    }

    hour %= 12;

    if (hour == 0) {
      hour += 12;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(hour.toString() + amPm, style: style),
    );
  }

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
        final temps = (data!["Temperatures"] as List)
            .map((val) => val as Map<String, dynamic>)
            .toList();
        var i = -1.0, j = -1;

        return AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              50,
              40,
              25,
            ),
            child: LineChart(
              LineChartData(
                minX: 0.0,
                maxX: temps.length.toDouble() - 1,
                minY: 0.0,
                maxY: 26.0 * 0.5,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: leftTitles,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomTitles,
                      interval: 8,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(width: 2, color: Colors.white),
                    bottom: BorderSide(width: 2, color: Colors.white),
                  ),
                ),
                lineTouchData: LineTouchData(
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map(
                      (spotIdx) {
                        return TouchedSpotIndicatorData(
                          FlLine(strokeWidth: 4, color: Colors.white),
                          FlDotData(
                            getDotPainter: (p0, p1, p2, p3) {
                              return FlDotCirclePainter(
                                radius: 8,
                                color: Colors.white,
                              );
                            },
                          ),
                        );
                      },
                    ).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${temps[spot.x.toInt()]["avgTemperature"]}",
                          TextStyle(color: Colors.black),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: temps.map((t) {
                      i++;
                      return FlSpot(i, t["adjTemperature"] as double);
                    }).toList(),
                    isCurved: false,
                    barWidth: 3,
                    color: Colors.white,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(90, 255, 255, 255),
                          Colors.transparent
                        ],
                        end: Alignment.bottomCenter,
                        begin: Alignment.topCenter,
                        stops: [0.4, 1.0],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) =>
                          FlDotCirclePainter(radius: 6, color: Colors.white),
                    ),
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