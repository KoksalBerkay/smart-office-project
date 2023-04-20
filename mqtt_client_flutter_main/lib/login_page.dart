import 'package:flutter/material.dart';
import 'mqtt_client_wrapper.dart';
import 'home_page.dart';

late MQTTClientWrapper newclient;
var topic;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _username;
  late String _password;
  late String _host;
  late int _port;
  late String _topic;

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
                onSaved: (value) {
                  _username = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                ),
                onSaved: (value) {
                  _password = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your host',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your host';
                  }
                  return null;
                },
                onSaved: (value) {
                  _host = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your port',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your port';
                  }
                  return null;
                },
                onSaved: (value) {
                  _port = int.parse(value!);
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your topic',
                ),
                onSaved: (value) {
                  _topic = value!;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState?.save();
                      // do something with the form data
                      print('Username: $_username');
                      print('Password: $_password');
                      print('Host: $_host');
                      print('Port: $_port');
                      print('Topic: $_topic');

                      topic = _topic;

                      newclient = new MQTTClientWrapper();
                      _prepareMqttClient(
                          newclient, _username, _password, _host, _port);

                      // clear the form
                      _formKey.currentState?.reset();

                      // navigate to the next page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
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

void _prepareMqttClient(MQTTClientWrapper client, String username,
    String password, String host, int port) async {
  client.prepareMqttClient(username, password, host, port);
  await client.connectionState == MqttCurrentConnectionState.CONNECTED;
}
