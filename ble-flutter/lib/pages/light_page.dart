import 'package:flutter/material.dart';
import '../home_page.dart';
import '../main.dart';
import '../mqtt_client_wrapper.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LightPage extends StatefulWidget {
  const LightPage({Key? key}) : super(key: key);

  @override
  _LightPageState createState() => _LightPageState();
}

class _LightPageState extends State<LightPage> {
  int light = 0; //0
  String? actualValue = "";
  int thresholdValue = 0; //0
  double _sliderValue = 0;
  String? state = "";
  MQTTClientWrapper mqttClientWrapper = MQTTClientWrapper();

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.prepareMqttClient("", "", mqttIp, 1883);

    // wait for the client to connect
    Future.delayed(const Duration(seconds: 1)).then((_) {
      print("subscribing...");
      mqttClientWrapper.subscribeToTopic("light\\$uuid")?.listen((message) {
        setState(() {
          print("Message: " + message);

          // Add the logic to parse the mqtt messages here
          List<String> messageList = message.split('/');

          actualValue = messageList[0];
          print(actualValue![0]);
          if (actualValue![0] == "T") {
            null;
          } else {
            light = int.parse(actualValue!);
            thresholdValue = int.parse(messageList[1]);
            state = messageList[2];
            _sliderValue = thresholdValue / 36;
            if (state == "1") {
              state = "ON";
            } else if (state == "0") {
              state = "OFF";
            }

            print("Light: $light");
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
                      radius: 160,
                      lineWidth: 14,
                      animateFromLastPercent: true,
                      percent: thresholdValue / 3600, // THIS MIGHT NOT WORK
                      progressColor: Colors.indigo,
                      center: Column(
                        children: [
                          const SizedBox(height: 116),
                          Text(
                            // light -> gelen ışık verisi || threshold -> threshold verisi
                            'Light: %${(light / 36).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            // light -> gelen ışık verisi || threshold -> threshold verisi
                            'Threshold: %${(thresholdValue / 36).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            // light -> gelen ışık verisi || threshold -> threshold verisi
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
                        'LIGHT',
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
                              'BRIGHTNESS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Slider(
                                value: _sliderValue,
                                label: _sliderValue.round().toString(),
                                max: 100,
                                divisions: 100,
                                onChanged: (double value) {
                                  setState(() {
                                    _sliderValue = value;
                                    thresholdValue =
                                        (_sliderValue * 36).toInt();
                                    mqttClientWrapper.publishMessage(
                                        'T$thresholdValue',
                                        'light\\$uuid');
                                  });
                                },
                              )
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
