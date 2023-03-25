import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mqtt/mqtt_client_wrapper.dart';

void main() {
  test('mqtt client wrapper test', () async {
    MQTTClientWrapper newclient = MQTTClientWrapper(); // Initialize the object
    String host = 'localhost';
    int port = 1883;
    String username = '';
    String password = '';
    String topicName = 'temp';

    // Prepare the client for connection
    await newclient.prepareMqttClient(username, password, host, port);

    // Subscribe to a topic
    Stream<String> topicStream = newclient.subscribeToTopic(topicName);

    // Publish a message to the topic
    newclient.publishMessage('test message', topicName);

    // Wait for the message to be received
    await Future.delayed(
        Duration(seconds: 1)); // Add a delay to ensure message is received
    String receivedMessage = await topicStream.first;

    expect(receivedMessage, 'test message');
  });
}
