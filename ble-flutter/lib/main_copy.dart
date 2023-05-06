import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BTStream(),
    );
  }
}

class BTStream extends StatefulWidget {
  const BTStream({super.key});

  @override
  State<BTStream> createState() => _BTStreamState();
}

class _BTStreamState extends State<BTStream> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBluePlus.instance.state,
      initialData: BluetoothState.unknown,
      builder: ((context, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return const PairingScreen();
        } else {
          return BluetoothOffScreen(state: state);
        }
      }),
    );
  }
}

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String teamManufacturerData =
      "4B49: [4C, 20, 53, 6F, 66, 74, 77, 61, 72, 65, 20, 43, 6C, 75, 62]";
  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 5));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Pairing Screen"),
      ),
      body: Column(
        children: [
          StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.instance.scanResults,
            initialData: const [],
            builder: (c, snapshot) {
              snapshot.data!.map((scannedDevice) {
                print(scannedDevice.device.name + " <---------");
                if (scannedDevice.advertisementData.manufacturerData ==
                    teamManufacturerData) {
                  scannedDevice.device.connect();
                  print("Connected!");
                }
                return PairingFailedPage();
              });
              return PairingFailedPage();
            },
          ),
          Text("Pairing device..."),
        ],
      ),
    );
  }
}

class PairingSuccessfulPage extends StatelessWidget {
  const PairingSuccessfulPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pairing Successful!"),
      ),
      body: const Icon(Icons.done),
    );
  }
}

class PairingFailedPage extends StatelessWidget {
  const PairingFailedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
