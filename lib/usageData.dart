import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:savenergizer/responsive.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  DateTime today;
  DateTime aWeekAgo;
  var usageData = [];
  var sensorReadings = [];

  var checkedForUsageData = false;
  var checkedForSensorReadings = false;

  @override
  Widget build(BuildContext context) {
    var resp = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: sensorReadings.isNotEmpty && usageData.isNotEmpty &&
          checkedForSensorReadings && checkedForUsageData ?
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Uso en los últimos 7 días"),
          new charts.BarChart(
            _prepareUsageData(),
            animate: true,
            barGroupingType: charts.BarGroupingType.stacked,
          ),
          Text("Temperatura en el día"),
          new charts.LineChart(
              _prepareTemperatureData(),
              animate: true,
              defaultRenderer: new charts.LineRendererConfig(
                  includePoints: true)
          )
        ],
      ) :
      sensorReadings.isEmpty && usageData.isEmpty &&
          checkedForSensorReadings && checkedForUsageData ?
      Center(
        child: Padding(
            padding: EdgeInsets.all(resp.wp(5)),
            child: Text("Sin datos para mostrar")
        ),
      ) : Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text(
              "Cargando datos...",
              style: TextStyle(height: 3),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    today = DateTime.now();
    aWeekAgo = DateTime.now().subtract(Duration(days: 7,
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));
    var dayStart = today.subtract(Duration(
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));

    print("today: " +today.millisecondsSinceEpoch.toString());
    print("aweekago: " +aWeekAgo.millisecondsSinceEpoch.toString());
    print("daystart: " +dayStart.millisecondsSinceEpoch.toString());

    // get usage data
    if(usageData.isEmpty) FirebaseFirestore.instance.collection("usageData")
        .where("timeTurnedOn", isGreaterThanOrEqualTo: aWeekAgo.millisecondsSinceEpoch)
        .get()
        .then((docs) {
      print("valid usageData:" + docs.docs.isNotEmpty.toString());
      setState(() {
        checkedForUsageData = true;
        if(docs.docs.isNotEmpty)
          docs.docs.forEach((element) {
          usageData.add({
            "port": element.data()['port'],
            "timeTurnedOn": element.data()['timeTurnedOn'],
            "timeUsed": element.data()['timeUsed'],
            "timestamp": element.data()['timestamp']
          });
          print("Usage data ready");
        });
      });
    }, onError: (error) =>
        print("Error in usage data: " + error.toString())).catchError((error) => print("Error in usage data: " + error.toString()));
    // get sensor readings
    if(sensorReadings.isEmpty) FirebaseFirestore.instance.collection("sensorReadings")
        .where("timestamp", isGreaterThanOrEqualTo: dayStart)
        .get()
        .then((docs) {
          print("valid sensor readings: " + docs.docs.isNotEmpty.toString());
      setState(() {
        checkedForSensorReadings = true;
        if(docs.docs.isNotEmpty)
        docs.docs.forEach((element) {
          sensorReadings.add({
            "timestamp": element.data()['timestamp'],
            "value": element.data()['value']
          });
          print("Sensor readings ready");
        });
      });
    }, onError: (error) =>
        print("Error in sensor readings: " + error.toString())).catchError((error) =>
        print("Error in sensor readings: " + error.toString()));
  }

  List<charts.Series<LabelValue, String>> _prepareUsageData(){
    final port1Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port1").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];
    final port2Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port2").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];
    final port3Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port3").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];
    final port4Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port4").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];
    final port5Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port5").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];
    final port6Data = [
      new LabelValue(getWeekdayName(aWeekAgo.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
      new LabelValue(getWeekdayName(today.weekday) , usageData.where((element) => DateTime.fromMillisecondsSinceEpoch(element["timeTurnedOn"]).weekday == aWeekAgo.weekday && element["port"] == "port6").fold(0, (previousValue, element) => previousValue + element["timeUsed"])/1000),
    ];

    return [
      new charts.Series<LabelValue, String>(
        id: 'Puerto 1',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port1Data,
      ),
      new charts.Series<LabelValue, String>(
        id: 'Puerto 2',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port2Data,
      ),
      new charts.Series<LabelValue, String>(
        id: 'Puerto 3',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port3Data,
      ),
      new charts.Series<LabelValue, String>(
        id: 'Puerto 4',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port4Data,
      ),
      new charts.Series<LabelValue, String>(
        id: 'Puerto 5',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port5Data,
      ),
      new charts.Series<LabelValue, String>(
        id: 'Puerto 6',
        domainFn: (LabelValue lv, _) => lv.label,
        measureFn: (LabelValue lv, _) => lv.data,
        data: port6Data,
      ),
    ];
  }

  List<charts.Series<LinearReadings, int>> _prepareTemperatureData() {

    final dailyTemperature = [];
    final DateFormat formatter = DateFormat('HHmm');

    sensorReadings.forEach((reading) {
      dailyTemperature.add( new LinearReadings(
          int.parse(formatter.format(DateTime.fromMillisecondsSinceEpoch((reading["timestamp"] as Timestamp).millisecondsSinceEpoch))),
          reading["value"]));
    });

    return [
      new charts.Series<LinearReadings, int>(
        id: 'Temperatura en el día',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearReadings lv, _) => lv.time,
        measureFn: (LinearReadings lv, _) => lv.temperature,
        data: dailyTemperature,
      )
    ];
  }

  getWeekdayName(int d){
    switch(d){
      case 1: return "Lunes";
      case 2: return "Martes";
      case 3: return "Miércoles";
      case 4: return "Jueves";
      case 5: return "Viernes";
      case 6: return "Sábado";
      case 7: return "Domingo";
    }
  }
}

class LabelValue {
  final String label;
  final double data;

  LabelValue(this.label, this.data);
}

/// Sample linear data type.
class LinearReadings {
  final int time;
  final int temperature;

  LinearReadings(this.time, this.temperature);
}