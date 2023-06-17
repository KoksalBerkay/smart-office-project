import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../home_page.dart';

// const urlPrefix = 'https://192.168.1.97:8000';
const urlPrefix = 'http://192.168.1.12:8000';

String? uuid;
String dataType = '';
String displayDataType = '';
bool isSuccess = false;

Future<String> getUuid() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('UUID: ${prefs.getString('UUID')}');
  return prefs.getString('UUID') ?? '';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  DateRange? selectedRange;

  @override
  void initState() {
    super.initState();
    getUuid().then((value) {
      setState(() {
        uuid = value;
      });
    });
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
        selectedRange = null;
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
        selectedRange = null;
      });
    }
  }

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  String displayDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(dateTime);
  }

  void updateDateRange(DateRange range) {
    setState(() {
      selectedRange = range;
      switch (range) {
        case DateRange.lastWeek:
          startDate = DateTime.now().subtract(const Duration(days: 7));
          endDate = DateTime.now();
          break;
        case DateRange.last2Weeks:
          startDate = DateTime.now().subtract(const Duration(days: 14));
          endDate = DateTime.now();
          break;
        case DateRange.lastMonth:
          startDate = DateTime.now().subtract(const Duration(days: 30));
          endDate = DateTime.now();
          break;
        case DateRange.last3Months:
          startDate = DateTime.now().subtract(const Duration(days: 90));
          endDate = DateTime.now();
          break;
      }
    });
  }

  Future<void> makePostRequest() async {
    if (uuid != null) {
      // Perform a null check before using uuid
      final headers = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final data = {
        'uuid': uuid!,
        'data_type': dataType,
        'start_timestamp': startDate.millisecondsSinceEpoch,
        'stop_timestamp': endDate.millisecondsSinceEpoch,
      };

      print("DATA: $data");

      final url = Uri.parse('$urlPrefix/get_data/');

      final res =
          await http.post(url, headers: headers, body: jsonEncode(data));
      final status = res.statusCode;
      if (status == 200) {
        print("Status: $status");
        isSuccess = true;
      }
      print("BODY: ${res.body}");
      if (status != 200) {
        throw Exception('http.post error: statusCode=$status');
      }
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Range'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, DateRange.lastWeek);
                                  },
                                  child: const Text('Last Week'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(
                                        context, DateRange.last2Weeks);
                                  },
                                  child: const Text('Last 2 Weeks'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, DateRange.lastMonth);
                                  },
                                  child: const Text('Last Month'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(
                                        context, DateRange.last3Months);
                                  },
                                  child: const Text('Last 3 Months'),
                                ),
                              ],
                            ),
                          );
                        },
                      ).then((selectedRange) {
                        if (selectedRange != null) {
                          updateDateRange(selectedRange);
                        }
                      });
                    },
                    child: const Text('Select Date Range'),
                  ),
                  const SizedBox(height: 16, width: 32),
                  ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Custom Date'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'start');
                                },
                                child: const Text('Select Start Date'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'end');
                                },
                                child: const Text('Select End Date'),
                              ),
                            ],
                          ),
                        );
                      },
                    ).then((selectedDate) {
                      if (selectedDate == 'start') {
                        selectStartDate(context);
                      } else if (selectedDate == 'end') {
                        selectEndDate(context);
                      }
                    }),
                    child: const Text('Select Custom Dates'),
                  ),
                  const SizedBox(height: 16, width: 16),
                ],
              ),
              const SizedBox(
                height: 16,
              ),

              // choose data type
              Row(
                children: [
                  const SizedBox(width: 128),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Data Type'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, 'light');
                                  },
                                  child: const Text('Light'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, 'temperature');
                                  },
                                  child: const Text('Temperature'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, 'motion');
                                  },
                                  child: const Text('Motion'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, 'humidity');
                                  },
                                  child: const Text('Humidity'),
                                ),
                              ],
                            ),
                          );
                        },
                      ).then((selectedDataType) {
                        if (selectedDataType != null) {
                          setState(() {
                            if (selectedDataType == "temperature") {
                              displayDataType = "temperature";
                              dataType = "temp";
                            } else {
                              displayDataType = selectedDataType;
                              dataType = selectedDataType;
                            }
                          });
                        }
                      });
                    },
                    child: const Text('Select Data Type'),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 32, height: 16),
                  Text(
                    'Selected Data Type: $displayDataType',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 32),
                  Text(
                    'Selected Dates: ${displayDateTime(startDate)} - ${displayDateTime(endDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: makePostRequest,
                  child: const Text('Get Data'),
                ),
              ),
            ],
          ),
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
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.indigo),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum DateRange { lastWeek, last2Weeks, lastMonth, last3Months }
