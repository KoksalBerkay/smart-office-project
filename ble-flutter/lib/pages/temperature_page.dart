import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../home_page.dart';
import '../mqtt_client_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

late String uuid;
late String mqttPass;

// get the uuid from the shared preferences
Future<void> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uuid = prefs.getString('UUID')!;
  mqttPass = prefs.getString('MQTTPASSWORD')!;
  print('Got uuid: $uuid');
  print('Got mqttPass: $mqttPass');
}

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
    getUuid().then((_) {
      mqttClientWrapper.prepareMqttClient(uuid, mqttPass, mqttIp, 1883);

      // wait for the client to connect
      Future.delayed(const Duration(seconds: 1)).then((_) {
        // wait for to get the uuid
        print("subscribing...");
        mqttClientWrapper
            .subscribeToTopic("sensor-data/temp/$uuid")
            ?.listen((message) {
          setState(() {
            print("Message: $message");

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
              } else if (state == "0") {
                state = "OFF";
              }

              print("Heat: $heat");
              print('Threshold Value: $thresholdValue');
              print('State: $state');
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
                      center: Column(
                        children: [
                          const SizedBox(height: 116),
                          Text(
                            'Temperature: ${heat.toStringAsFixed(2)}\u00B0',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Threshold: ${thresholdValue.toStringAsFixed(2)}\u00B0',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'State: $state',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                              TextButton.icon(
                                icon: const Icon(Icons.remove),
                                label: const Text("0.5"),
                                onPressed: () {
                                  setState(() {
                                    if (thresholdValue > 0) {
                                      thresholdValue -= 0.5;
                                    }
                                    mqttClientWrapper.publishMessage(
                                        'T$thresholdValue',
                                        'sensor-data/temp/$uuid');
                                  });
                                },
                              ),
                              const SizedBox(width: 24),
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("0.5"),
                                onPressed: () {
                                  setState(() {
                                    if (thresholdValue < 40) {
                                      //30
                                      thresholdValue += 0.5;
                                    }
                                    mqttClientWrapper.publishMessage(
                                        'T$thresholdValue',
                                        'sensor-data/temp/$uuid');
                                  });
                                },
                              ),
                            ],
                          ),
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
