import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'pages/bluetooth_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'home_page.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() => runApp(const MyApp());

late String uuid;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  _scanconnect() async {
    String teamManufacturerData = "{16971: [77, 71]}";
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
          if (char.uuid.toString() == "4934c8ce-bce0-417c-b613-14f9f24da803") {
            await char.write(ssid.codeUnits, withoutResponse: true);
            print("Sent the wifi ssid successfully");
          }
          if (char.uuid.toString() == "7dec32af-0afe-4718-9c5b-a0c120bab609") {
            await char.write(pass.codeUnits, withoutResponse: true);
            print("Sent the wifi pass successfully");
          }
          if (char.uuid.toString() == "e91a0da9-9048-4b87-99a9-01a8a62b65bf") {
            await char.read().then((value) {
              uuid = String.fromCharCodes(value);
              nav();
              print("The uuid is: $uuid");
            });
          }
        }
        ;
      }
    }
  }

  final TextEditingController _ssidController = TextEditingController();
  Future<void> _initSSID() async {
    String? wifiName = await NetworkInfo().getWifiName();
    if (wifiName != null) {
      _ssidController.text = wifiName;
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
                  controller: _ssidController,
                  decoration: const InputDecoration(
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
                  decoration: const InputDecoration(
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
                    child: const Text('Submit'),
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
        children: const [
          Align(
              alignment: Alignment.center,
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              )),
        ],
      ),
    );
  }
}
