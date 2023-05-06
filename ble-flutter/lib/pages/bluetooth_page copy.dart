import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wakelock/wakelock.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool wakelockStatus = false;
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Connection Page"),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Press here to scan devices"),
              onPressed: () {
                // Start scanning
               
                flutterBlue.startScan(timeout: Duration(seconds: 3));
                print("Scan started");
// Listen to scan results
                var subscription = flutterBlue.scanResults.listen((results) {
                  for (ScanResult r in results) {
                    print("Scan startedXXXXXX");
                    //print(r.device.name);
                  }
                });
                print("Subscription -> "); 

// Stop scanning
                flutterBlue.stopScan();
              },
            ),
            SizedBox(
              width: 130,
              child: ElevatedButton(
                child: Row(
                  children: [
                    const Text("Wakelock"),
                    Icon(wakelockStatus ? Icons.add : Icons.backspace),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    wakelockStatus = !wakelockStatus;
                    wakelockStatus?Wakelock.enable()
                    :Wakelock.disable();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

scanBTDevices(FlutterBluePlus flutterBlue) {
  print('scanning');
  flutterBlue.startScan(timeout: const Duration(seconds: 4));
  var subscription = flutterBlue.scanResults.listen((results) {
    // do something with scan results
    for (ScanResult r in results) {
      print('${r.device.name} found! rssi: ${r.rssi}');
    }
    flutterBlue.stopScan();
  });
  flutterBlue.stopScan();
}
