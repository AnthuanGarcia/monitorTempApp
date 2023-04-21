class Ambient {
  final num movement;
  final num temperature;
  final num humidity;
  final num heatIndex;

  const Ambient(
      {required this.movement,
      required this.temperature,
      required this.humidity,
      required this.heatIndex});

  factory Ambient.fromJson(Map<String, dynamic> json) => Ambient(
      movement: json["test"]["move"] as int,
      temperature: json["test"]["temperature"] as double,
      humidity: json["test"]["humidity"] as double,
      heatIndex: json["test"]["heatIndex"] as double);

  factory Ambient.fromDbSnap(Map<dynamic, dynamic> snap) => Ambient(
      movement: snap["test"]["move"] as int,
      temperature: snap["test"]["temperature"] as double,
      humidity: snap["test"]["humidity"] as int,
      heatIndex: snap["test"]["heatIndex"] as double);
}
