import 'package:flutter/material.dart';
import 'mqtt_client_wrapper.dart';

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
      home: LoginPage(),
    );
  }
}

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

void _prepareMqttClient(MQTTClientWrapper client, String username,
    String password, String host, int port) async {
  client.prepareMqttClient(username, password, host, port);
  await client.connectionState == MqttCurrentConnectionState.CONNECTED;
}

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _textEditingController = TextEditingController();
  List<String> _messages = [];
  Stream<String>? _messageStream = newclient.subscribeToTopic(topic);

  void _sendMessage(String message) async {
    try {
      newclient.publishMessage(message, topic);
    } catch (e) {
      setState(() {
        _messages.add('Error publishing message: $e');
        print('Error publishing message: $e');
      });
    }

    _textEditingController.clear();
  }

  void _listenForMessages() async {
    // check if the stream is not null
    while (_messageStream == null) {
      // Wait for a short period of time before trying again
      print("Stream is null");
      await Future.delayed(Duration(seconds: 1));
      _messageStream = newclient.subscribeToTopic(topic);
    }
    print('Stream is not null');
    _messageStream?.listen((message) {
      setState(() {
        _messages.add(message);
      });
    }, onError: (e) {
      setState(() {
        _messages.add('Error receiving message: $e');
        print('Error receiving message: $e');
      });
    });
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
    _listenForMessages();
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
