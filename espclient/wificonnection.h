// eksik ve hatalı
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wifiClient;
PubSubClient client(wifiClient);


class MqttHandler {
  private:
    const char* serverIP;
    uint16_t port;
    String uuid;
    String wifiPass;
    String wifiSsid;
    //static void callback(char* topic, byte* payload, unsigned int length);
  public:
    void setUuid(String uuid);
    void setServerIP(String ipAddress);
    void setPort(uint16_t port);
    void setWifiPass(String wifiPass);
    void setWifiSsid(String wifiSsid);
    void setupWifi();
    void setupMQTT(void (*callback)(char*, byte*, unsigned int));
    boolean publishData(char* topic, float sensorData, float threshold, boolean stat);
    boolean reconnectTopics(char* topics[]);

    // void callback(char* topic, byte * payload, unsigned uint16_t length);


};

void MqttHandler::setServerIP(String ipAddress) {
  serverIP = ipAddress.c_str();
}

void MqttHandler::setPort(uint16_t port) {
  port = port;
}

void MqttHandler::setupWifi() {
  delay(10);
  // We start by connecting to a WiFi network
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(wifiSsid);

  WiFi.begin(wifiSsid.c_str(), wifiPass.c_str());

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}
void MqttHandler::setWifiPass(String wifiPass) {
  wifiPass = wifiPass;
}
void MqttHandler::setWifiSsid(String wifiSsid) {
  wifiSsid = wifiSsid;
}
void setWifiSsid(String wifiSsid);
void MqttHandler::setupMQTT(void (*callback)(char*, byte*, unsigned int)) {
  //setupWifi(ssid.c_str() , pass.c_str());
  client.setServer(serverIP, port);
  client.setCallback(callback);
  delay(1500);
}

void MqttHandler::setUuid(String uuid) {
  uuid = uuid;
}

//String MqttHandler::getUuid() {
//  return uuid;
//}

bool MqttHandler::publishData(char* topic, float sensorData, float threshold, boolean stat) {

  char topicData[50];
  bool ret;

  sprintf(topicData, "%s/%f/%f/%d", uuid.c_str(), sensorData, threshold, stat);

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

