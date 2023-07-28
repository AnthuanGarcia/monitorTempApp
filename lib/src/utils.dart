import 'package:vector_math/vector_math.dart';

class Utils {
  static const weekDays = [
    "Domingo",
    "Lunes",
    "Martes",
    "Miércoles",
    "Jueves",
    "Viernes",
    "Sábado",
  ];

  static const months = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  static String weekDay(int day, int month, int year) {
    List<int> t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
    if (month < 3) year--;
    return weekDays[
        (year + year ~/ 4 - year ~/ 100 + year ~/ 400 + t[month - 1] + day) %
            7];
  }

  static Vector3 Lerp(Vector3 a, Vector3 b, double t) {
    return Vector3(
      (1.0 - t) * a.x + t * b.x,
      (1.0 - t) * a.y + t * b.y,
      (1.0 - t) * a.z + t * b.z,
    );
  }
}
