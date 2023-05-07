import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'pages/bluetooth_page.dart';

import 'home_page.dart';

void main() => runApp(const MyApp());

//TODO: Disconnect from the ble device and navigate to the home_page.dart after we have sent and received data from the device
//TODO: Automatically fill the ssid field with the ssid of the connected wifi using a library

bool isConnecting = false;
bool isConnected = false;

bool isSending = false;
bool isReceiving = false;

bool isSent = false;
bool isReceived = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BleHomePage(title: 'Flutter BLE Demo'),
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
            title: 'Bluetooth Demo',
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
          isConnecting = true;

          flutterBlue.stopScan();
          print('Scan stopped');
          mydevice = r.device;
          await mydevice?.connect(
              autoConnect: true, timeout: const Duration(seconds: 10));

          if (mydevice!.state == BluetoothDeviceState.connected) {
            isConnected = true;
            _characteristicUpdater(mydevice!);
            print('connected to device');
            break;
          } else if (mydevice!.state != BluetoothDeviceState.connected) {
            print('not connected to device');
            continue;
          }
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
          isSending = true;
          await characteristic.write(ssid.codeUnits); //added await
          print("Sent the wifi ssid successfully");
        }
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "7dec32af-0afe-4718-9c5b-a0c120bab609") {
          isSending = true;
          await characteristic.write(pass.codeUnits); //added await
          print("Sent the wifi password successfully");
        }
        // the code below is for reading the uuid of the device
        // it is not verified yet we have to try it
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "e91a0da9-9048-4b87-99a9-01a8a62b65bf") {
          isReceiving = true;
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
    if (isConnecting) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ConnectingScreen()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
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

class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({super.key});

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      isConnecting = false;
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ConnectedScreen()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Align(
              alignment: Alignment.center,
              child: Text("Connecting to the device...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class ConnectedScreen extends StatefulWidget {
  const ConnectedScreen({super.key});

  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen> {
  @override
  Widget build(BuildContext context) {
    if (isSending || isReceiving) {
      // this might not work maybe && instead of ||
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CharacteristicUpdatingScreen()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Align(
              alignment: Alignment.center,
              child: Text("Connected to the device",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class CharacteristicUpdatingScreen extends StatefulWidget {
  const CharacteristicUpdatingScreen({super.key});

  @override
  State<CharacteristicUpdatingScreen> createState() =>
      _CharacteristicUpdatingScreenState();
}

class _CharacteristicUpdatingScreenState
    extends State<CharacteristicUpdatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Screen"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Align(
              alignment: Alignment.center,
              child: Text("Connected to the device",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
