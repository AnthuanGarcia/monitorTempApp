import 'package:flutter/material.dart';

class LogsTemperature extends StatefulWidget {
  const LogsTemperature({super.key});

  @override
  State<LogsTemperature> createState() => _LogsTemperatureState();
}

class _LogsTemperatureState extends State<LogsTemperature> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text("Temps")),
    );
  }
}
