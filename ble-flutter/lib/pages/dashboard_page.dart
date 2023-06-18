import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../home_page.dart';
import 'visualization_page.dart';

// const urlPrefix = 'https://192.168.1.97:8000';
const urlPrefix = 'http://192.168.1.12:8000';

String? uuid;
String dataType = '';
String displayDataType = '';
String visualData = '';
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

  void processAndVisualizeData(Map<String, dynamic> data) {
    StringBuffer buffer = StringBuffer();

    data.forEach((key, value) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(key));

      String timestamp = DateFormat('yyyy.MM.dd')
          .format(dateTime); // Format the timestamp as yyyy.MM.dd
      String entry = '$timestamp: ';

      List<String> values = List<String>.from(value);
      String dataValue = values[0];
      String thresholdValue = values[1];
      String state = values[2] == '0' ? 'off' : 'on';

      entry += 'Data: $dataValue, Threshold: $thresholdValue, State: $state\n';

      buffer.write(entry);
    });

    visualData = buffer.toString();
    print(visualData);

    // navigate to the visualization page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VisualizationPage(),
      ),
    );
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

      print("SEND DATA: $data");

      final url = Uri.parse('$urlPrefix/get_data/');

      final res =
          await http.post(url, headers: headers, body: jsonEncode(data));
      final status = res.statusCode;
      print("RESPONSE BODY: ${res.body}");
      if (status == 200) {
        isSuccess = true;
        Map<String, dynamic> responseData =
            jsonDecode(res.body); // Parse the response data as a Map
        processAndVisualizeData(
            responseData); // Process and visualize the received data
      }
      print("Request Status: $status");
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.indigo),
                    ),
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.indigo),
                    ),
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
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              // choose data type
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.indigo),
                    ),
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 32),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selected Dates: ${displayDateTime(startDate)} - ${displayDateTime(endDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.indigo),
                  ),
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
