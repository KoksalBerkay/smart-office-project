import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'login_page.dart';
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
        home: MyHomePage(title: 'Flutter BLE Demo'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  @override
  void initState() {
    super.initState();
    _scanconnect();
  }

  _scanconnect() async {
    // String teamManufacturerData = "{6: [1, 9, 32, 2, 154, 92, 46, 202, 168, 8, 8, 17, 172, 189, 112, 3, 216, 0, 97, 59, 24, 136, 223, 251, 6, 109, 3]}";
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

          _characteristicUpdater(mydevice!);
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
          String ssid = "a";
          characteristic.write(ssid.codeUnits);
          print("Sent the wifi ssid successfully");
        }
        if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" &&
            characteristic.uuid.toString() ==
                "7dec32af-0afe-4718-9c5b-a0c120bab609") {
          String pass = "b";
          characteristic.write(pass.codeUnits);
          print("Sent the wifi password successfully");
        }
        // if (service.uuid.toString() == "c2302aa0-0548-49ff-a10a-e421fdb311ff" && characteristic.uuid.toString() == "e91a0da9-9048-4b87-99a9-01a8a62b65bf") {

        // }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[],
        ),
      );
}
