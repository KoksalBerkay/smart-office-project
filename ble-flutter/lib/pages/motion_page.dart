import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mqtt_client_wrapper.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../home_page.dart';

late String uuid;

// get the uuid from the shared preferences
Future<void> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uuid = prefs.getString('uuid')!;
}

class MotionPage extends StatefulWidget {
  const MotionPage({Key? key}) : super(key: key);

  @override
  _MotionPageState createState() => _MotionPageState();
}

class _MotionPageState extends State<MotionPage> {
  double motion = 0.0;
  String? actualValue = "";
  double thresholdValue = 0.0;
  String? state = "";
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
        mqttClientWrapper.subscribeToTopic("motion\\$uuid")?.listen((message) {
          setState(() {
            print("Message: " + message);
            List<String> messageList = message.split('/');
            actualValue = messageList[0];
            if (actualValue![0] == 'T') {
              null;
            } else {
              motion = double.parse(actualValue!);
              thresholdValue = double.parse(messageList[1]);
              state = messageList[2];
              if (state == '1') {
                state = 'ON';
              }
              if (state == '0') {
                state = 'OFF';
              }

              print("Motionless time: $motion");
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
                    animateFromLastPercent: true,
                    radius: 180,
                    lineWidth: 14,
                    percent: thresholdValue / 18000, //thresholdValue/180,
                    progressColor: Colors.indigo,

                    center: Column(
                      children: [
                        SizedBox(height: 132),
                        Text(
                          'Motionless Time: ${(motion / 60).toStringAsFixed(1)} min.',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Threshold: ${(thresholdValue.toInt() / 60).toStringAsFixed(0)} min.',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Motion: $state',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'MOTION',
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
                            'TIME SETTING',
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
                              label: const Text("10 min"),
                              onPressed: () {
                                setState(() {
                                  if (thresholdValue > 0) {
                                    thresholdValue -= 600.0;
                                  }
                                  mqttClientWrapper.publishMessage(
                                      'T$thresholdValue', 'motion\\$uuid');
                                });
                              },
                            ),
                            const SizedBox(width: 24),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("10 min"),
                              onPressed: () {
                                setState(() {
                                  if (thresholdValue < 72000) {
                                    //180
                                    thresholdValue += 600.0;
                                  }
                                  mqttClientWrapper.publishMessage(
                                      'T$thresholdValue', 'motion\\$uuid');
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
