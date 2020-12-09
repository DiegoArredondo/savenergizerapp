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

  var minTempAxis = 2400;
  var maxTempAxis = 0;

  @override
  Widget build(BuildContext context) {
    var resp = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: usageData.isNotEmpty && checkedForUsageData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: resp.wp(5)),
                child: Text("Minutos encendidos por puerto en los ultimpos 7 días",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: resp.ip(2)
                ),),),
                Container(
                  height: resp.hp(40),
                  margin: EdgeInsets.only(bottom: resp.hp(5)),
                  child: charts.BarChart(
                    _prepareUsageData(),
                    animate: true,
                    barGroupingType: charts.BarGroupingType.stacked,
                    behaviors: [new charts.SeriesLegend()],
                  ),
                ),
                Text("Temperatura en el día",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: resp.ip(2)
                ),),
                Container(
                    height: resp.hp(25),
                    width: resp.wp(90),
                    child: charts.LineChart(
                      _prepareTemperatureData(),
                      animate: true,
                      defaultRenderer: new charts.LineRendererConfig(
                        includePoints: true,
                      ),
                      domainAxis: new charts.NumericAxisSpec(
                        // Set the initial viewport by providing a new AxisSpec with the
                        // desired viewport, in NumericExtents.
                          viewport: new charts.NumericExtents(minTempAxis, maxTempAxis)),
                      // Optionally add a pan or pan and zoom behavior.
                      // If pan/zoom is not added, the viewport specified remains the viewport.
                      behaviors: [new charts.PanAndZoomBehavior()],
                    )),
              ],
            )
          : usageData.isEmpty && checkedForUsageData
              ? Center(
                  child: Padding(
                      padding: EdgeInsets.all(resp.wp(5)),
                      child: Text("Sin datos para mostrar")),
                )
              : Center(
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
    aWeekAgo = DateTime.now().subtract(Duration(
        days: 6,
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));
    var dayStart = today.subtract(Duration(
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));

    print("today: " + today.millisecondsSinceEpoch.toString());
    print("aweekago: " + aWeekAgo.millisecondsSinceEpoch.toString());
    print("daystart: " + dayStart.millisecondsSinceEpoch.toString());

    // get usage data
    if (usageData.isEmpty)
      FirebaseFirestore.instance
          .collection("usageData")
          .where("timeTurnedOn",
              isGreaterThanOrEqualTo: aWeekAgo.millisecondsSinceEpoch)
          .get()
          .then((docs) {
        print("valid usageData:" + docs.docs.isNotEmpty.toString());
        setState(() {
          checkedForUsageData = true;
          if (docs.docs.isNotEmpty)
            docs.docs.forEach((element) {
              usageData.add({
                "port": element.data()['port'],
                "timeTurnedOn": element.data()['timeTurnedOn'] as int,
                "timeUsed": element.data()['timeUsed'] as int,
                "timestamp": element.data()['timestamp'] as int
              });
              print("Usage data ready");
            });
        });
      },
              onError: (error) =>
                  print("Error in usage data: " + error.toString())).catchError(
              (error) => print("Error in usage data: " + error.toString()));
    // get sensor readings
    if (sensorReadings.isEmpty)
      FirebaseFirestore.instance
          .collection("sensorReadings")
          .where("timestamp", isGreaterThanOrEqualTo: dayStart)
          .get()
          .then((docs) {
        print("valid sensor readings: " + docs.docs.isNotEmpty.toString());
        setState(() {
          checkedForSensorReadings = true;
          if (docs.docs.isNotEmpty)
            docs.docs.forEach((element) {
              sensorReadings.add({
                "timestamp": element.data()['timestamp'],
                "value": element.data()['value']
              });
              print("Sensor readings ready");

              minTempAxis = usageData[0]["timestamp"];
              sensorReadings.forEach((element) {
                var t = element["value"];
                if (t < minTempAxis) minTempAxis = t;
                if (t > maxTempAxis) maxTempAxis = t;
              });
              print("minTempAxis: " + minTempAxis.toString());
              print("maxTempAxis: " + maxTempAxis.toString());
            });
        });
      },
              onError: (error) => print(
                  "Error in sensor readings: " + error.toString())).catchError(
              (error) =>
                  print("Error in sensor readings: " + error.toString()));
  }

  List<charts.Series<OrdinalUsage, String>> _prepareUsageData() {
    print("weekAgo " + aWeekAgo.toString());
    var day1 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:0)).weekday;});
    var day2 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:1)).weekday;});
    var day3 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:2)).weekday;});
    var day4 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:3)).weekday;});
    var day5 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:4)).weekday;});
    var day6 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:5)).weekday;});
    var day7 = usageData.where((ud){ return DateTime.fromMillisecondsSinceEpoch(ud["timestamp"] as int).weekday == aWeekAgo.add(Duration(days:6)).weekday;});

    final port1Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port1").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port1").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];
    final port2Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port2").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port2").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];
    final port3Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port3").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port3").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];
    final port4Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port4").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port4").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];
    final port5Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port5").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port5").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];
    final port6Data = [
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 0)).weekday), day1.isEmpty ? 0 : day1.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day1.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 1)).weekday), day2.isEmpty ? 0 : day2.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day2.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 2)).weekday), day3.isEmpty ? 0 : day3.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day3.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 3)).weekday), day4.isEmpty ? 0 : day4.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day4.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 4)).weekday), day5.isEmpty ? 0 : day5.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day5.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 5)).weekday), day6.isEmpty ? 0 : day6.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day6.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
      new OrdinalUsage(getWeekdayName(aWeekAgo.add(Duration(days: 6)).weekday), day7.isEmpty ? 0 : day7.where((ud) => ud["port"] == "port6").isEmpty ? 0 : day7.where((ud) => ud["port"] == "port6").fold(0, (previousValue, element) => previousValue + (element["timeUsed"]/60000 as double).toInt())),
    ];

    return [
      new charts.Series<OrdinalUsage, String>(
        id: 'Port1',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port1Data,
      ),
      new charts.Series<OrdinalUsage, String>(
        id: 'Port2',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port2Data,
      ),
      new charts.Series<OrdinalUsage, String>(
        id: 'Port3',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port3Data,
      ),
      new charts.Series<OrdinalUsage, String>(
        id: 'Port4',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port4Data,
      ),
      new charts.Series<OrdinalUsage, String>(
        id: 'Port5',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port5Data,
      ),
      new charts.Series<OrdinalUsage, String>(
        id: 'Port6',
        domainFn: (OrdinalUsage sales, _) => sales.day,
        measureFn: (OrdinalUsage sales, _) => sales.usage,
        data: port6Data,
      ),
    ];
  }

  List<charts.Series<LinearReadings, int>> _prepareTemperatureData() {
    //sensorReadings
    //timestamp dateTme
    //value int
    var format = DateFormat('HH:mm');

    final DateFormat formatter = DateFormat('HHmm');

    List<LinearReadings> data = [];

    sensorReadings.forEach((reading) {
      int i = int.parse(formatter.format(DateTime.fromMillisecondsSinceEpoch(
          (reading["timestamp"] as Timestamp).millisecondsSinceEpoch)));
      data.add(new LinearReadings(i, reading["value"] as int));
    });

    return [
      new charts.Series<LinearReadings, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearReadings sales, _) => sales.time,
        measureFn: (LinearReadings sales, _) => sales.temp,
        data: data,
      )
    ];
  }

  getWeekdayName(int d) {
    switch (d) {
      case 1:
        return "Lunes";
      case 2:
        return "Martes";
      case 3:
        return "Miércoles";
      case 4:
        return "Jueves";
      case 5:
        return "Viernes";
      case 6:
        return "Sábado";
      case 7:
        return "Domingo";
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
  final int temp;

  LinearReadings(this.time, this.temp);
}

/// Sample ordinal data type.
class OrdinalUsage {
  final String day;
  final int usage;

  OrdinalUsage(this.day, this.usage);
}
