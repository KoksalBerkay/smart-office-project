import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mqtt_client_wrapper.dart';

late String uuid;

// get the uuid from the shared preferences
Future<void> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uuid = prefs.getString('uuid')!;
}

class HumidityPage extends StatefulWidget {
  const HumidityPage({Key? key}) : super(key: key);

  @override
  _HumidityPageState createState() => _HumidityPageState();
}

class _HumidityPageState extends State<HumidityPage> {
  double humidity = 0.0;
  String? actualValue = "";
  MQTTClientWrapper mqttClientWrapper = MQTTClientWrapper();

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.prepareMqttClient("", "", mqttIp, 1883);

    // wait for the client to connect
    Future.delayed(const Duration(seconds: 1)).then((_) {
      // wait for to get the uuid
      getUuid().then((_) {
        print("subscribing...");
        mqttClientWrapper
            .subscribeToTopic("humidity\\$uuid")
            ?.listen((message) {
          setState(() {
            print("Message: " + message);

            List<String> messageList = message.split('/');

            actualValue = messageList[0];

            if (actualValue![0] == "T") {
              null;
            } else {
              humidity = double.parse(actualValue!);

              print("Humidity: $humidity");
            }
          });
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    mqttClientWrapper.client.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
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
                  const RotatedBox(
                    quarterTurns: 135,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.indigo,
                      size: 28,
                    ),
                  )
                ],
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 64),
                    CircularPercentIndicator(
                      radius: 180,
                      lineWidth: 14,
                      percent: humidity / 100,
                      progressColor: Colors.indigo,
                      center: Column(
                        children: [
                          const SizedBox(height: 164),
                          Text(
                            'Humidity: ${humidity.toStringAsFixed(2)} gr/m³',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Humidity',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
