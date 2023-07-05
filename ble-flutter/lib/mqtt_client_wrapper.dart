import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:shared_preferences/shared_preferences.dart';

// DISCLAIMER: Unsubscribe func is not tested.

// connection states for easy identification
enum MqttCurrentConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  errorWhenConnecting
}

enum MqttSubscriptionState { idle, subscribed }

class MQTTClientWrapper {
  late MqttServerClient client;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.idle;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.idle;

  void prepareMqttClient(
      String username, String password, String host, int port) async {
    // Check if the username and password are empty if so setup the client without
    // authentication

    if (username.isEmpty && password.isEmpty) {
      _setupMqttClientWithoutAuth(host, port);
    } else {
      _setupMqttClientWithAuth(username, host, port);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('UUID')!;

    // delay to wait for the uuid to be gotten from the shared preferences
    await Future.delayed(const Duration(milliseconds: 100));

    client.clientIdentifier = '${uuid}_mobile';

    // check the if the username and password are empty if so connect to the client without
    // authentication

    if (username.isEmpty && password.isEmpty) {
      await _connectClientWithoutAuth();
    } else {
      await _connectClientWithAuth(username, password);
    }
  }

  Future<void> _connectClientWithAuth(String username, String password) async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.connecting;
      await client.connect(username, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.connected;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      client.disconnect();
    }
  }

  Future<void> _connectClientWithoutAuth() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.connecting;
      await client.connect();
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.connected;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.errorWhenConnecting;
      client.disconnect();
    }
  }

  void _setupMqttClientWithAuth(String username, String host, int port) {
    client = MqttServerClient.withPort(host, username, port);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.autoReconnect = true;
  }

  void _setupMqttClientWithoutAuth(String host, int port) {
    client = MqttServerClient.withPort(host, '', port);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.autoReconnect = true;
  }

  Stream<String>? subscribeToTopic(String topicName) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('ERROR: client is not connected');
      return null;
    }

    print('Subscribing to the $topicName topic');

    final controller = StreamController<String>();

    // q: write the code to subscribe to the topic after the connection is established
    client.subscribe(topicName, MqttQos.exactlyOnce); //mostOnce

    // Set up a listener to receive incoming messages
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;

      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $message');
      controller.add(message); // Add the received message to the stream
    });

    return controller.stream;
  }

  // unsubscribe from a topic
  void unsubscribeFromTopic(String topicName) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('ERROR: client is not connected');
      return;
    }

    print('Unsubscribing from the $topicName topic');
    client.unsubscribe(topicName);
  }

//_
  void publishMessage(String message, String topicName) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic $topicName');
    client.publishMessage(topicName, MqttQos.exactlyOnce, builder.payload!);
  }

  // callbacks for different events
  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.subscribed;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.disconnected;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.connected;
    print('OnConnected client callback - Client connection was sucessful');
  }
}
