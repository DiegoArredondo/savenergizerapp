import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:savenergizer/push_nofitications.dart';
import 'package:savenergizer/responsive.dart';
import 'package:savenergizer/usageData.dart';

class AlertsPage extends StatefulWidget {
  AlertsPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  var alerts = [];

  @override
  void initState() {
    FirebaseFirestore.instance.collection('alert').get().then((qSnaps) {
      setState(() {
        alerts.clear();
        print(qSnaps.docs.isNotEmpty);
        qSnaps.docs.forEach((element) {
          alerts.add({
            "level": element["alertLevel"],
            "timestamp": element["timestamp"],
            "value": element["value"],
          });
        });
        print(alerts.toString());
      });
    });

    FirebaseFirestore.instance.collection('alert').snapshots().listen((qSnaps) {
      setState(() {
        alerts.clear();
        qSnaps.docs.forEach((element) {
          alerts.add({
            "level": element["alertLevel"],
            "timestamp": element["timestamp"],
            "value": element["value"],
          });
        });
        print(alerts.toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var resp = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("alerts").snapshots(),
          builder: (context, snapshot) {
            return alerts.isNotEmpty
                ? Center(
                    child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: resp.ip(2.5), vertical: resp.hp(5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Ultimas alertas lanzadas:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: resp.ip(2),
                              height: 3),
                        ),
                        Column(
                          children: List.generate(alerts.length, (index) {
                            var alert = alerts[index];
                            return Container(
                                height: resp.hp(7.5),
                                margin: EdgeInsets.only(bottom: resp.hp(1)),
                                child: RaisedButton(
                                  onPressed: () => {},
                                  color: alert["level"] == "NORMAL"
                                      ? Colors.white
                                      : Colors.orangeAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        alert["value"].toString() + "ºC",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: resp.ip(4)),
                                      ),
                                      Text(
                                        "a las " +
                                            DateTime.fromMillisecondsSinceEpoch(
                                                    (alert["timestamp"]
                                                            as Timestamp)
                                                        .millisecondsSinceEpoch)
                                                .toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: resp.ip(1.5)),
                                      ),
                                    ],
                                  ),
                                ));
                          }),
                        )
                      ],
                    ),
                  ))
                : Center(
                    child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text(
                        "Cargando...",
                        style: TextStyle(height: 2),
                      )
                    ],
                  ));
          }),
    );
  }
}
