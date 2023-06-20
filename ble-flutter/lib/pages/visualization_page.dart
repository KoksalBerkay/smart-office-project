import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_page.dart';

void processAndVisualizeData(Map<String, dynamic> rdata) {
  StringBuffer buffer = StringBuffer();

  String data = '';
  String threshold = '';
  String state = '';

  rdata.forEach((key, value) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(key));

    String timestamp = DateFormat('yyyy.MM.dd / hh:mm').format(dateTime);
    String entry = '$timestamp: ';

    List<String> values = List<String>.from(value);

    if (dataType == "light") {
      double dataValue = double.parse(values[0]);
      data = "%${(dataValue / 40).toStringAsFixed(2)}";

      double thresholdValue = double.parse(values[1]);
      threshold = "%${(thresholdValue / 40).toStringAsFixed(2)}";

      state = values[2] == '0' ? 'OFF' : 'ON';

      entry += '\nData: $data, Threshold: $threshold, State: $state\n\n';
    } else if (dataType == "motion") {
      double dataValue = double.parse(values[0]);
      data = "${(dataValue / 60).toStringAsFixed(2)} min. ";

      double thresholdValue = double.parse(values[1]);
      threshold = "${(thresholdValue / 60).toStringAsFixed(2)} min. ";

      state = values[2] == '0' ? 'OFF' : 'ON';

      entry += '\nData: $data, Threshold: $threshold, State: $state\n\n';
    } else if (dataType == "temp") {
      double dataValue = double.parse(values[0]);
      data = "${dataValue.toStringAsFixed(2)}\u00B0";

      double thresholdValue = double.parse(values[1]);
      threshold = "${thresholdValue.toStringAsFixed(2)}\u00B0";

      state = values[2] == '0' ? 'OFF' : 'ON';

      entry += '\nData: $data, Threshold: $threshold, State: $state\n\n';
    } else if (dataType == "humidity") {
      double dataValue = double.parse(values[0]);
      data = "${dataValue.toStringAsFixed(2)} gr/m³";

      entry += '\nData: $data\n\n';
    }

    buffer.write(entry);
  });

  visualData = buffer.toString();
}

class VisualizationPage extends StatefulWidget {
  const VisualizationPage({Key? key}) : super(key: key);

  @override
  _VisualizationPageState createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {
  @override
  void initState() {
    super.initState();
    processAndVisualizeData(responseData);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          backgroundColor: Colors.indigo.shade50,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.indigo,
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(top: 18, left: 24, right: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add your widgets for the 'Data' tab here
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          displayDataType.toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(child: Text(visualData)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
