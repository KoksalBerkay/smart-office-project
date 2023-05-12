import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../home_page.dart';
import '../main.dart';
import '../mqtt_client_wrapper.dart';

//TODO: Check the connection state and display a message if the connection is lost
//TODO: Make sure the connection is re-established when the connection is lost
//TODO: Add a loading indicator when the connection is being established
//TODO: Make sure that the connection is established before subscribing to a topic
// ! Make sure that the format of message publishing is correct

class TemperaturePage extends StatefulWidget {
  const TemperaturePage({Key? key}) : super(key: key);

  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  double heat = 0.0;
  String? actualValue = "";
  double thresholdValue = 0;
  String? state = "";
  MQTTClientWrapper mqttClientWrapper = MQTTClientWrapper();

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.prepareMqttClient("", "", mqttIp, 1883);

    // wait for the client to connect
    Future.delayed(const Duration(seconds: 1)).then((_) {
      print("subscribing...");
      mqttClientWrapper.subscribeToTopic("temp$uuid")?.listen((message) {
        setState(() {
          print("Message: " + message);

          List<String> messageList = message.split('/');

          actualValue = messageList[0];

          if (actualValue![0] == "T") {
            null;
          } else {
            heat = double.parse(actualValue!);
            thresholdValue = double.parse(messageList[1]);
            state = messageList[2];

            if (state == "1") {
              state = "ON";
            }
            else if (state == "0") {
              state = "OFF";
            }

            print("Heat: $heat");
            print('Threshold Value: $thresholdValue');
            print('State: $state');
          }
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
                    const SizedBox(height: 32),
                    CircularPercentIndicator(
                      radius: 180,
                      lineWidth: 14,
                      percent: thresholdValue / 40, //30
                      progressColor: Colors.indigo,
                      center: Text(
                        '${heat.toStringAsFixed(2)}\u00B0\n${thresholdValue.toStringAsFixed(2)}\u00B0\n$state',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'TEMPERATURE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'HEATING',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (thresholdValue > 0) {
                                      thresholdValue -= 0.5;
                                    }
                                    mqttClientWrapper.publishMessage(
                                        'T$thresholdValue', 'temp$uuid');
                                  });
                                },
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    if (thresholdValue < 40) {
                                      //30
                                      thresholdValue += 0.5;
                                    }
                                    mqttClientWrapper.publishMessage(
                                        'T$thresholdValue', 'temp$uuid');
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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
