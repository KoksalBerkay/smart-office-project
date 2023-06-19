import 'package:flutter/material.dart';
import 'dashboard_page.dart';

void processData(String visualData) {
  // Split the visualData string by line breaks
  List<String> lines = visualData.split('\n');

  // Iterate through each line
  for (String line in lines) {
    // Remove leading and trailing whitespace from the line
    line = line.trim();

    // Skip empty lines
    if (line.isEmpty) {
      continue;
    }

    // Split the line by commas
    List<String> values = line.split(',');

    // Extract the individual values
    double? data;
    double? threshold;
    String state = '';

    for (String value in values) {
      // Remove leading and trailing whitespace from each value
      value = value.trim();

      // Extract the data value
      if (value.startsWith('Data:')) {
        data = double.tryParse(value.split(':')[1]);
      }
      // Extract the threshold value
      else if (value.startsWith('Threshold:')) {
        threshold = double.tryParse(value.split(':')[1]);
      }
      // Extract the state value
      else if (value.startsWith('State:')) {
        state = value.split(':')[1].trim();
      }
    }

    // Perform your desired control statements with the extracted values
    if (data != null && threshold != null) {
      // CONTROL STATEMENT
      if (dataType == "light") {
        data = double.parse((data / 40).toStringAsFixed(2));
        threshold = double.parse((threshold / 40).toStringAsFixed(2));
        print("Translated Data: $data, Threshold: $threshold, State: $state");
      }
      else if (dataType == "temp") {
        print("Translated Data: $data, Threshold: $threshold, State: $state");
      }
      else if (dataType == "motion") {
        data = double.parse((data / 60).toStringAsFixed(2));
        threshold = double.parse((threshold / 60).toStringAsFixed(2));
        print("Translated Data: $data, Threshold: $threshold, State: $state");
      }
      else if (dataType == "humidity") {
        print("Translated Data: $data, Threshold: $threshold, State: $state");
      }
    }
  }
}

class VisualizationPage extends StatefulWidget {
  const VisualizationPage({Key? key}) : super(key: key);

  @override
  _VisualizationPageState createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {

  void initState() {
    super.initState();
    processData(visualData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(top: 18, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                // Add more widgets here
                const SizedBox(height: 32),
                Center(child: Text("${dataType.toUpperCase()} DATA", style: const TextStyle(fontSize: 32))),
                const SizedBox(height: 32),
                Text(visualData),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
