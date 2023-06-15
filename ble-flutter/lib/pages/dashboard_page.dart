import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../home_page.dart';

const urlPrefix = 'http://192.168.1.97:8000';

late String uuid;
bool isSuccess = false;

// get the uuid from the shared preferences
Future<void> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uuid = prefs.getString('UUID')!;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    getUuid();
  }

  Future<void> selectStartDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        startDate = selectedDate;
      });
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        endDate = selectedDate;
      });
    }
  }

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  Future<void> makePostRequest() async {
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    print('FOUND UUID: $uuid');
    final data = {
      'uuid': uuid,
      'data_type': 'temp',
      'start_timestamp': startDate.millisecondsSinceEpoch,
      'stop_timestamp': endDate.millisecondsSinceEpoch,
    };
    print('DATA: $data');

    final url = Uri.parse('http://192.168.1.97:8000/get_data/');

    final res = await http.post(url, headers: headers, body: jsonEncode(data));
    final status = res.statusCode;
    if (status == 200) {
      isSuccess = true;
    }
    print("BODY: ${res.body}");
    if (status != 200) throw Exception('http.post error: statusCode= $status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade50,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.indigo,
                size: 28,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => selectStartDate(context),
              child: const Text('Select Start Date'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => selectEndDate(context),
              child: const Text('Select End Date'),
            ),
            const SizedBox(height: 16),
            Text(
              'Start Date: ${formatDateTime(startDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'End Date: ${formatDateTime(endDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: makePostRequest,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 100,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.indigo),
            title: const Text('Home'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.indigo),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
