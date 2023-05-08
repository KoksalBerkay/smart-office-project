// eksik ve hatalı
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wifiClient;
PubSubClient client(wifiClient);


class MqttHandler {
  private:
    static String serverIP;
    static uint16_t port;
    static String* uuid;
    static void callback(char* topic, byte* payload, unsigned int length);
  public:
    void setUuid(String uuid);
    void setServerIP(String ipAddress);
    void setPort(uint16_t port);
    void setupWifi(const char* ssid , const char* pass);
    void setupMQTT();
    boolean publishData(char* topic, float sensorData, float threshold, boolean stat, String uuid);
    boolean reconnectTopics(char* topics[]);

    // void callback(char* topic, byte * payload, unsigned int length);


};

void MqttHandler::setServerIP(String ipAddress) {
  this->serverIP = ipAddress;
}

void MqttHandler::setPort(uint16_t port) {
  this->port = port;
}

void MqttHandler::setupWifi(const char* ssid , const char* pass) {
  delay(10);
  // We start by connecting to a WiFi network
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, pass);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void MqttHandler::setupMQTT() {
  //setupWifi(ssid.c_str() , pass.c_str());
  client.setServer(serverIP.c_str(), *port);
  client.setCallback(callback);
  delay(1500);
}

void MqttHandler::setUuid(String uuid) {
  this->uuid = uuid;
}

String MqttHandler::getUuid() {
  return this->uuid;
}

bool MqttHandler::publishData(char* topic, float sensorData, float threshold, boolean stat, String uuid) {

  char topicData[50];
  bool ret;

  sprintf(topicData, "%f/%f/%d", sensorData, threshold, stat);

  client.unsubscribe(topic);
  ret = client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
  client.subscribe(topic);
  return ret;
}

boolean MqttHandler::reconnectTopics(char* topics[]) {
  Serial.print("Reconnect...");
  if (client.connect("arduinoClient")) {
    // Once connected, publish an announcement...
    // ... and resubscribe
    for (int i = 0; i < 4; i++) {
      client.subscribe(topics[i]);
    }
  }
  Serial.print("Error Code :"); Serial.println(client.state());
  return client.connected();
}


