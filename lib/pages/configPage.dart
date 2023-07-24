import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Config extends StatefulWidget {
  const Config({super.key});

  @override
  State<Config> createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  DatabaseReference dbrt = FirebaseDatabase.instance.ref();

  static const styleHead = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w300,
  );

  static const styleBody = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w300,
  );

  List<String> resetInfo = [
    "Se ha reiniciado el microntrolador",
    "Error al reiniciar",
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dbrt.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Text("ERROR");
        }

        if (!snapshot.hasData) {
          return Text("No data");
        }

        final config = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final ip = config["config"]["ip"] as String;
        final ssid = config["config"]["ssid"] as String;
        final ping = Ping(ip);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 16),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Table(
                  border: TableBorder.all(color: Colors.transparent),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("Direccion IP:", style: styleHead),
                      ),
                      Text(ip, style: styleBody),
                    ]),
                    TableRow(children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("SSID:", style: styleHead),
                      ),
                      Text(ssid, style: styleBody),
                    ])
                  ],
                ),
              ),
              Spacer(flex: 3),
              StreamBuilder(
                stream: ping.stream,
                builder: (context, snapshot) {
                  final ipTest = snapshot.data?.response?.ip;
                  bool isConnected = ipTest == ip;

                  if (!snapshot.hasData ||
                      snapshot.hasError ||
                      ipTest == null) {
                    return Flex(
                      direction: Axis.vertical,
                      children: [
                        Image(
                          image: AssetImage('assets/imgs/warning_ad.png'),
                          fit: BoxFit.fitHeight,
                          height: MediaQuery.of(context).size.width * .45,
                          width: MediaQuery.of(context).size.width * .45,
                        ),
                        Text("Desconectado", style: styleBody),
                        SizedBox(
                          height: MediaQuery.of(context).size.width * .45,
                        ),
                        Text(
                          "Es necesario que el microcontrolador este en linea y debes estar conectado a la misma red para esta operacion",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        )
                      ],
                    );
                  }

                  return Flex(
                    direction: Axis.vertical,
                    children: [
                      Image(
                        image: AssetImage('assets/imgs/check.png'),
                        fit: BoxFit.fitHeight,
                        height: MediaQuery.of(context).size.width * .38,
                        width: MediaQuery.of(context).size.width * .38,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width * .05),
                      Text("Conectado", style: styleBody),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * .45,
                      ),
                      InkWell(
                        onTap: () {
                          http.get(Uri.parse("http://$ip:80/reset")).then(
                            (res) {
                              if (res.statusCode == 200) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Reinicio Exitoso"),
                                    content: Text(resetInfo[0]),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'OK'),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Reinicio Fallido"),
                                    content: Text(resetInfo[1]),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'OK'),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.height * .3,
                          padding: EdgeInsets.all(16),
                          child: isConnected
                              ? Text(
                                  "Reiniciar",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300),
                                )
                              : CircularProgressIndicator(),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(60),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
