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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savenergizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Savenergizer'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MqttClient mqttClient;
  final pubTopic = 'data';
  final builder = MqttClientPayloadBuilder();

  // AQUI DECLARAS NUEVAS VARIABLES SI LAS OCUPAS, COMO POR EJEMPLO
  //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  List<bool> portsStates = [false, false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    var resp = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection("portStates").snapshots(),
          builder: (context, snapshot) {
            FirebaseFirestore.instance
                .collection('portStates')
                .get()
                .then((qSnaps) {
              int i = 0;
              setState(() {
                while (i < qSnaps.docs.length) {
                  //print("port" + (i+1).toString() + " set to " + qSnaps.docs[i].data['state'].toString());
                  portsStates[i] = qSnaps.docs[i].data()['state'];
                  i++;
                }
              });
            });

            return mqttClient == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: Text(
                            "Puertos:",
                            style: TextStyle(
                                fontSize: resp.ip(2.5),
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(70, 70, 70, 1)),
                          ),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            portsStates.length,
                            (index) => Container(
                              width: resp.wp(40),
                              height: resp.wp(40),
                              margin: EdgeInsets.all(resp.ip(1)),
                              child: RaisedButton(
                                onPressed: () async {
                                  /*
                THIS IS FOR SENDING IT TO THE MQTT
                builder.clear();
                builder.addString("port" + (index+1).toString() + (portsStates[index] ? "-off" : "-on"));
                mqttClient
                    .publishMessage(
                    pubTopic, MqttQos.exactlyOnce, builder.payload)
                    .toString();*/
                                  var portState = portsStates[index];
                                  var updatingData;
                                  var lastTimeOn;
                                  if (!portState) {
                                    // if it was off
                                    updatingData = {
                                      "state": true,
                                      "lastTimeOn": DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toInt()
                                    };
                                  } else {
                                    //it was on
                                    updatingData = {
                                      "state": false,
                                    };
                                    // get the lastTimeOn for usageData
                                    await FirebaseFirestore.instance
                                        .collection('portStates')
                                        .doc('port' + (index + 1).toString())
                                        .get()
                                        .then((data) {
                                      print("lastTimeOnFetched");
                                      lastTimeOn = data.data()["lastTimeOn"];
                                    },
                                            onError: (error) => print(
                                                "No encontre el lastTimeOn: " +
                                                    error.toString()));
                                  }

                                  // Turn it off / on
                                  await FirebaseFirestore.instance
                                      .collection('portStates')
                                      .doc('port' + (index + 1).toString())
                                      .update(updatingData)
                                      .then((value) async {
                                    if (portState) {
                                      //it was turned off
                                      print("Port turned off");
                                      var ts =
                                          DateTime.now();
                                      // usageData write
                                      await FirebaseFirestore.instance
                                          .collection('usageData')
                                          .add({
                                        "port": 'port' + (index + 1).toString(),
                                        "timeTurnedOn": lastTimeOn,
                                        "timeUsed": ts.subtract(Duration(milliseconds: lastTimeOn)).millisecondsSinceEpoch,
                                        "timestamp": ts
                                      });
                                    }
                                  }).catchError((error) => {print(error)});
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(FontAwesomeIcons.powerOff,
                                        size: resp.ip(5),
                                        color: portsStates[index]
                                            ? Colors.blueAccent
                                            //? Color.fromRGBO(255, 223, 5, 1)
                                            : Colors.blueGrey),
                                    Text("Puerto " +
                                        (index == 5
                                            ? 'USB'
                                            : (index + 1).toString())),
                                    //Text("Turn " + (portsStates[index] ? "off" : "on"))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: resp.ip(5),
                          width: resp.wp(50),
                          child: RaisedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DashboardPage(
                                            title: "Dashboard",
                                          )));
                            },
                            child: Text(
                              "Ir a Dashboard",
                              style: TextStyle(
                                  color: Colors.white, fontSize: resp.ip(2)),
                            ),
                            color: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        )
                      ],
                    ),
                  )
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
      /*floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), */
    );
  }

  Future<MqttServerClient> connect() async {
    MqttServerClient client =
        MqttServerClient.withPort('192.168.100.4', 'flutter_client', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    /*final connMessage = MqttConnectMessage()
        .authenticateAs('username', 'password')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;*/

    try {
      await client.connect();
      client.subscribe("states", MqttQos.atLeastOnce);
      //client.subscribe("data", MqttQos.atLeastOnce);
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client != null){
      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        // payload = port2-off
        print('!!!!!Received message: $payload from topic: ${c[0].topic}>');
        int port = int.parse(payload.split("-")[0].split("t")[1]) - 1;
        setState(() {
          portsStates[port] =
              payload.split("-")[1] == "on" || payload.split("-")[1] == "True";
        });
      }, onError: (error) => {print("Received error: " + error.toString())});
    }
    return client;

  }

  // connection succeeded
  void onConnected() {
    print('Connected');
  }

// unconnected
  void onDisconnected() {
    print('Disconnected');
  }

// subscribe to topic succeeded
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

// subscribe to topic failed
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

// unsubscribe succeeded
  void onUnsubscribed(String topic) {
    print('Unsubscribed topic: $topic');
  }

// PING response received
  void pong() {
    print('Ping response client callback invoked');
  }

  @override
  void initState() {
    if (mqttClient == null) {
      connect().then((value) => setState(() => {mqttClient = value}));
    }
    // AQUI HAZ LO DE LAS NOTIFICACIONES
    PushNotificationsManager().init();
  }

}
