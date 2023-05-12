class Ambient {
  final num movement;
  final num temperature;
  final num humidity;
  final num heatIndex;

  const Ambient(
      {this.movement = 0,
      this.temperature = 0,
      this.humidity = 0,
      this.heatIndex = 0});

  factory Ambient.fromJson(Map<String, dynamic> json) => Ambient(
      movement: json["move"] as num,
      temperature: json["temperature"] as num,
      humidity: json["humidity"] as num,
      heatIndex: json["heatIndex"] as num);

  factory Ambient.fromDbSnap(Map<dynamic, dynamic> snap) => Ambient(
        movement: snap["test"]["move"] as num,
        temperature: snap["test"]["temperature"] as num,
        humidity: snap["test"]["humidity"] as num,
        heatIndex: snap["test"]["heatIndex"] as num,
      );
}
