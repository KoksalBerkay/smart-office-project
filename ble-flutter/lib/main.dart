import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'pages/bluetooth_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'home_page.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final uuidExists = await checkUuidExists();
  final mqttPasswordExists = await checkMqttPasswordExists();
  if (uuidExists && mqttPasswordExists) {
    runApp(const MqttApp());
  } else {
    // Gather and save UUID using Bluetooth
    runApp(const BleApp());
  }
}

const urlPrefix = 'http://192.168.1.97:8000';
// const urlPrefix = 'http://192.168.1.11:8000';

bool isSuccess = false;
Map<String, dynamic> responseData = {};

late String uuid;
late String mqttPassword;

Future<bool> checkUuidExists() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.setString('UUID', 'deneme-uuid'); // TESTING
    uuid = prefs.getString('UUID')!;
    print('UUID is found: $uuid');
    return uuid.isNotEmpty;
  } catch (e) {
    print('Could not find the UUID: $e');
    return false;
  }
}

Future<bool> checkMqttPasswordExists() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.setString('MQTTPASSWORD', 'deneme-sifre'); // TESTING
    mqttPassword = prefs.getString('MQTTPASSWORD')!;
    print('MQTTPASSWORD is found: $mqttPassword');
    return mqttPassword.isNotEmpty;
  } catch (e) {
    print('Could not find the mqttPassword: $e');
    return false;
  }
}

Future<void> saveUuid(String uuid) async {
  print('SAVING UUID...');
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('UUID', uuid);
    final a = prefs.getString('UUID');
    print('Saved UUID: $a');
  } catch (e) {
    print('Error at saveUuid: $e');
  }
}

Future<void> saveMqttPassword(String uuid) async {
  print('SAVING mqttPassword...');
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('MQTTPASSWORD', mqttPassword);
    final b = prefs.getString('MQTTPASSWORD');
    print('Saved MQTTPASSWORD: $b');
  } catch (e) {
    print('Error at saveUuid: $e');
  }
}

class MqttApp extends StatelessWidget {
  const MqttApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MQTT Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      );
}

class BleApp extends StatelessWidget {
  const BleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const BleHomePage(title: "BLE Demo"),
      );
}

class BleHomePage extends StatefulWidget {
  const BleHomePage({super.key, required this.title});

  final String title;

  @override
  State<BleHomePage> createState() => _BleHomePageState();
}

class _BleHomePageState extends State<BleHomePage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBluePlus.instance.state,
      initialData: BluetoothState.unknown,
      builder: ((context, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return BlePage(
            title: 'Bluetooth Page',
          );
        } else {
          return BluetoothOffScreen(state: state);
        }
      }),
    );
  }
}

class BlePage extends StatefulWidget {
  BlePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];

  @override
  _BlePageState createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final _formKey = GlobalKey<FormState>();
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  late String ssid;
  late String pass;

  @override
  void initState() {
    super.initState();
    _initSSID();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    super.dispose();
  }

  _scanConnect() async {
    String teamManufacturerData = "{16971: [77, 71]}";
    // Start scanning
    flutterBlue.startScan(timeout: const Duration(seconds: 2));
    print('start scan work');
    late BluetoothDevice? mydevice;

    flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
        var cleanData = r.advertisementData.manufacturerData.toString();
        print('->$cleanData<-');

        if (cleanData == teamManufacturerData) {
          flutterBlue.stopScan();
          print('Scan stopped');
          mydevice = r.device;
          await mydevice?.connect(
              autoConnect: true, timeout: const Duration(seconds: 5));

          _characteristicUpdater(mydevice!);
          print('connected to device');
          break;
        }
      }
      print('for loop work');
    });
  }

  void nav() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const HomePage()));
  }

  _characteristicUpdater(BluetoothDevice mydevice) async {
    List<BluetoothService> services = await mydevice.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff") {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == "340ab508-1009-11ee-be56-0242ac120002") {
            await char.read().then((value) {
              mqttPassword = String.fromCharCodes(value);
              if (mqttPassword == "") {
                throw Exception("mqttPassword is empty so go get it again!!!");
              } else {
                saveMqttPassword(mqttPassword);
              }
              print("The mqttPassword is: $mqttPassword");
            });
            Future.delayed(const Duration(milliseconds: 500));
          } else if (char.uuid.toString() ==
              "e91a0da9-9048-4b87-99a9-01a8a62b65bf") {
            await char.read().then((value) {
              uuid = String.fromCharCodes(value);
              if (uuid == "") {
                throw Exception("UUID is empty so go get it again!!!");
              } else {
                saveUuid(uuid);
              }
              print("The uuid is: $uuid");
              Future.delayed(const Duration(milliseconds: 500));
            });
          } else if (char.uuid.toString() ==
              "4934c8ce-bce0-417c-b613-14f9f24da803") {
            char.write(ssid.codeUnits, withoutResponse: true);
            print("Sent the wifi ssid successfully");
            Future.delayed(const Duration(milliseconds: 500));
          } else if (char.uuid.toString() ==
              "7dec32af-0afe-4718-9c5b-a0c120bab609") {
            char.write(pass.codeUnits, withoutResponse: true);
            print("Sent the wifi pass successfully");
            Future.delayed(const Duration(milliseconds: 500));
          }
          print("CHARACTERISTICS: ${char.uuid.toString()}");
        }
      }
    }
    if (uuid != "" && mqttPassword != "") {
      final headers = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final data = {
        'username': uuid,
        'password': mqttPassword,
      };

      print("SEND DATA: $data");

      final url = Uri.parse('$urlPrefix/register/');

      final res =
          await http.post(url, headers: headers, body: jsonEncode(data));
      final status = res.statusCode;
      print("RESPONSE BODY: ${res.body}");

      if (status == 200) {
        isSuccess = true;
        responseData = jsonDecode(res.body); // Parse the response data as a Map
        nav();
      }
      print("Request Status: $status");
      if (status != 200) {
        throw Exception('http.post error: statusCode=$status');
      }
    }
  }

  final TextEditingController _ssidController = TextEditingController();
  Future<void> _initSSID() async {
    String? wifiName = await NetworkInfo().getWifiName();
    if (wifiName != null) {
      _ssidController.text = wifiName.replaceAll('"', "");
    } else {
      print('wifiName is null');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Form(
                key: _formKey, // Assign the _formKey to the Form widget
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 80.0), // Added space above the form
                    TextFormField(
                      controller: _ssidController,
                      decoration: const InputDecoration(
                        labelText: 'Wi-Fi SSID',
                        hintText: 'Enter your Wi-Fi SSID',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        ssid = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null; // Return null for no validation errors
                      },
                    ),
                    const SizedBox(height: 16.0), // Added vertical spacing
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your Wi-Fi password',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        pass = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null; // Return null for no validation errors
                      },
                    ),
                    const SizedBox(height: 32.0), // Added vertical spacing
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _scanConnect();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanningScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Submit',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Scanning Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 100),
          Align(
              alignment: Alignment.center,
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              )),
          SizedBox(height: 150),
          Text(
            "This should not take more than one minute.",
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
