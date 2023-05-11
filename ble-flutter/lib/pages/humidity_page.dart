import 'package:flutter/material.dart';
import '../main.dart';
import '../mqtt_client_wrapper.dart';

class HumidityPage extends StatefulWidget {
  const HumidityPage({Key? key}) : super(key: key);

  @override
  _HumidityPageState createState() => _HumidityPageState();
}

class _HumidityPageState extends State<HumidityPage> {
  MQTTClientWrapper mqttClientWrapper = MQTTClientWrapper();

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.prepareMqttClient("", "", "192.168.0.108", 1883);

    // wait for the client to connect
    Future.delayed(const Duration(seconds: 1)).then((_) {
      print("subscribing...");
      mqttClientWrapper.subscribeToTopic("humidity$uuid")?.listen((message) {
        setState(() {
          print("Message: " + message);

          // Add the logic to parse the mqtt messages here
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
                children: const [
                  SizedBox(height: 32),
                  Center(
                    child: Text(
                      "data",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: Text(
                      'HUMIDITY',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
