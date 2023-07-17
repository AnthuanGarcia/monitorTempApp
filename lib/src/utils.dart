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
    year -= (month < 3) as int;
    return weekDays[
        (year + year ~/ 4 - year ~/ 100 + year ~/ 400 + t[month - 1] + day) %
            7];
  }
}
