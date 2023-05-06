import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'pages/bluetooth_page.dart';

import 'home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(title: 'Flutter BLE Demo'),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBluePlus.instance.state,
      initialData: BluetoothState.unknown,
      builder: ((context, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return BlePage(
            title: 'Bluetooth Demo',
          );
        } else {
          return BluetoothOffScreen(state: state);
        }
      }),
    );
  }
}

//TODO: Create a widget for the screen after we have connected to the device
//TODO: Create another widget for sending and receiving data from the device
//TODO: Navigate to the home_page.dart after we have sent and received data from the device
//TODO: Automatically fill the ssid field with the ssid of the connected wifi using a library

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

  // @override
  // void initState() {
  //   super.initState();
  //   _scanconnect();
  // }

  _scanconnect() async {
    String teamManufacturerData = "{16971: [77, 71]}";
    String deviceName = 'ESPROOM32-XX';
    // Start scanning
    flutterBlue.startScan(timeout: const Duration(seconds: 2));
    print('start scan work');
    late BluetoothDevice? mydevice;

    var subscription = flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
        var cleanData = r.advertisementData.manufacturerData.toString();
        print('->' + cleanData + '<-');

        if (cleanData == teamManufacturerData) {
          flutterBlue.stopScan();
          print('Scan stopped');
          mydevice = r.device;
          await mydevice?.connect(
              autoConnect: true, timeout: const Duration(seconds: 10));

          if (mydevice!.state == BluetoothDeviceState.connected &&
              ssid != null &&
              pass != null) {
            print('connected to device and ssid and pass is not null');
            _characteristicUpdater(mydevice!);
          } else if (mydevice!.state == BluetoothDeviceState.connected &&
              ssid == null &&
              pass == null) {
            print('connected to device and ssid and pass is null');
          } else if (mydevice!.state != BluetoothDeviceState.connected) {
            print('not connected to device');
          }

          // _characteristicUpdater(mydevice!);
          print('connected to device');
          break;
        }
      }
      print('for loop work');
    });
  }

  _characteristicUpdater(BluetoothDevice mydevice) async {
    List<BluetoothService> services = await mydevice.discoverServices();
    for (var service in services) {
      service.characteristics.forEach((characteristic) async {
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "4934c8ce-bce0-417c-b613-14f9f24da803") {
          // String ssid = "a";
          characteristic.write(ssid.codeUnits);
          print("Sent the wifi ssid successfully");
        }
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "7dec32af-0afe-4718-9c5b-a0c120bab609") {
          // String pass = "b";
          characteristic.write(pass.codeUnits);
          print("Sent the wifi password successfully");
        }
        // the code below is for reading the uuid of the device
        // it is not verified yet we have to try it
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "e91a0da9-9048-4b87-99a9-01a8a62b65bf") {
          String uuid;
          await characteristic.read().then((value) {
            uuid = String.fromCharCodes(value);
            print("The uuid is $uuid");
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your wifi ssid',
                  ),
                  onSaved: (value) {
                    ssid = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your wifi password',
                  ),
                  onSaved: (value) {
                    pass = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _scanconnect();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ScanningScreen()));
                      }
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
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
        children: [
          Align(
              alignment: Alignment.center,
              child: Text("Scanning devices...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}
