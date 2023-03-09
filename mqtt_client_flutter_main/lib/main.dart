import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Mqtt Client App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _username;
  String _password;
  String _host;
  int _port;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Mqtt Client App'),
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
                  hintText: 'Enter your username',
                ),
                // validator: (value) {
                //   if (value.isEmpty) {
                //     return 'Please enter your username';
                //   }
                //   return null;
                // },
                onSaved: (value) {
                  _username = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                ),
                // validator: (value) {
                //   if (value.isEmpty) {
                //     return 'Please enter your password';
                //   }
                //   return null;
                // },
                onSaved: (value) {
                  _password = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your host',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter your host';
                  }
                  return null;
                },
                onSaved: (value) {
                  _host = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your port',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter your port';
                  }
                  return null;
                },
                onSaved: (value) {
                  _port = int.parse(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      // do something with the form data
                      print('Username: $_username');
                      print('Password: $_password');
                      print('Host: $_host');
                      print('Port: $_port');

                      MQTTClientWrapper newclient = new MQTTClientWrapper();
                      newclient.prepareMqttClient(
                          _username, _password, _host, _port);

                      // clear the form
                      _formKey.currentState.reset();

                      // navigate to the next page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageScreen(),
                        ),
                      );
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
}

// ToDo: create a new page for the message screen
class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}

// connection states for easy identification
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

class MQTTClientWrapper {
  MqttServerClient client;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  void prepareMqttClient(
      String username, String password, String host, int port) async {
    // Check if the username and password are empty if so setup the client without
    // authentication

    if (username.isEmpty && password.isEmpty) {
      _setupMqttClientWithoutAuth(host, port);
    } else {
      _setupMqttClientWithAuth(username, host, port);
    }

    // Set a unique identifier for the client
    final uniqueIdentifier =
        'myClientId-${DateTime.now().millisecondsSinceEpoch}';
    client.clientIdentifier = uniqueIdentifier;

    // check the if the username and password are empty if so connect to the client without
    // authentication

    if (username.isEmpty && password.isEmpty) {
      await _connectClientWithoutAuth();
    } else {
      await _connectClientWithAuth(username, password);
    }

    _subscribeToTopic('Dart/Mqtt_client/testtopic');
    _publishMessage('Hello');
  }

  Future<void> _connectClientWithAuth(String username, String password) async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(username, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  Future<void> _connectClientWithoutAuth() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect();
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  void _setupMqttClientWithAuth(String username, String host, int port) {
    client = MqttServerClient.withPort(host, username, port);
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void _setupMqttClientWithoutAuth(String host, int port) {
    client = MqttServerClient.withPort(host, '', port);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void _subscribeToTopic(String topicName) {
    print('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);

    // print the message when it is received
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('YOU GOT A NEW MESSAGE:');
      print(message);
    });
  }

  void _publishMessage(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print(
        'Publishing message "$message" to topic ${'Dart/Mqtt_client/testtopic'}');
    client.publishMessage(
        'Dart/Mqtt_client/testtopic', MqttQos.exactlyOnce, builder.payload);
  }

  // callbacks for different events
  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was sucessful');
  }
}
