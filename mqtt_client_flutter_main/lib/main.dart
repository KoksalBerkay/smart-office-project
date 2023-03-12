import 'dart:io';
import 'package:flutter/material.dart';
import 'mqtt_client_wrapper.dart';

void main() {
  runApp(MyApp());
}

MQTTClientWrapper newclient;

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
                onSaved: (value) {
                  _username = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                ),
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

                      newclient = new MQTTClientWrapper();
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

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _textEditingController = TextEditingController();
  List<String> _messages = [];
  Stream<String> _messageStream;

  void _sendMessage(String message) async {
    try {
      await newclient.publishMessage(message, 'Dart/Mqtt_client/testtopic');
      setState(() {
        _messages.add(message);
      });
    } catch (e) {
      setState(() {
        _messages.add('Error publishing message: $e');
        print('Error publishing message: $e');
      });
    }

    _textEditingController.clear();
  }

  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_messages[index]),
        );
      },
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration.collapsed(
                hintText: 'Type a message',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage(_textEditingController.text);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _messageStream = newclient.subscribeToTopic('Dart/Mqtt_client/testtopic');
    _messageStream?.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }
}
