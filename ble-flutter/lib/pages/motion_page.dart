import 'package:flutter/material.dart';
import '../main.dart';
import '../mqtt_client_wrapper.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../home_page.dart';

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

            print("Motion: " + motion.toString());
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
                    animateFromLastPercent: true,
                    radius: 180,
                    lineWidth: 14,
                    percent: thresholdValue / 1800, //thresholdValue/180,
                    progressColor: Colors.indigo,

                    center: Column(
                      children: [
                        SizedBox(height: 132),
                        Text(
                          'Motionless Time: ${(motion / 60).toStringAsFixed(0)} min.',
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
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (thresholdValue > 0) {
                                    thresholdValue -= 10.0;
                                  }
                                  mqttClientWrapper.publishMessage(
                                      'T$thresholdValue', 'motion\\$uuid');
                                });
                              },
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  if (thresholdValue < 7200) {
                                    //180
                                    thresholdValue += 10.0;
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
