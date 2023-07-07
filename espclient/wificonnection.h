// eksik ve hatalı
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wifiClient;
    PubSubClient client(wifiClient);


class MqttHandler {
  private:
    String serverIP;
    uint16_t port;
    String uuid;
    String wifiPass;
    String wifiSsid;
    String mqttPass;
    
    
    //static void callback(char* topic, byte* payload, unsigned int length);
  public:
    PubSubClient getMqttHandler();
    void setUuid(String uuid);
    void setMqttPass(String mqttPass);
    void setServerIP(String ipAddress);
    void setPort(uint16_t port);
    void setWifiPass(String wifiPass);
    void setWifiSsid(String wifiSsid);
    void setupWifi();
    void setupMQTT(void (*callback)(char*, byte*, unsigned int));
    boolean publishData(const char* topic, float sensorData, float threshold, boolean stat);
    boolean reconnectTopics(char* topics[]);
    String receiveMAC();
    // void callback(char* topic, byte * payload, unsigned uint16_t length);


};

PubSubClient getMqttHandler(){
  return client;
}

String MqttHandler::receiveMAC(){
  return WiFi.macAddress();
}
void MqttHandler::setServerIP(String ipAddress) {
  this->serverIP = ipAddress;
}

void MqttHandler::setPort(uint16_t port) {
  this->port = port;
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
  this->wifiPass = wifiPass;
}
void MqttHandler::setWifiSsid(String wifiSsid) {
  this->wifiSsid = wifiSsid;
}

void MqttHandler::setupMQTT(void (*callbackfunc)(char*, byte*, unsigned int)) {
  //setupWifi(ssid.c_str() , pass.c_str());
  Serial.println("Connecting to server -> " + String(serverIP));
  client.setServer(serverIP.c_str(), port);
  Serial.println("Connected to Server");
  client.setCallback(callbackfunc);
  delay(1500);
}

void MqttHandler::setUuid(String uuid) {
  this->uuid = uuid;
}

void MqttHandler::setMqttPass(String mqttPass) {
  this->wifiPass = wifiPass;
}
//String MqttHandler::getUuid() {
//  return uuid;
//}

bool MqttHandler::publishData(const char* topic, float sensorData, float threshold, boolean stat) {

  char topicData[100];
  bool ret;

  sprintf(topicData, "%f/%f/%d", sensorData, threshold, stat);

  //client.unsubscribe(topic);
  ret = client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
  //client.subscribe(topic);
  return ret;
}

//13p%*0K9mvZ#V

boolean MqttHandler::reconnectTopics(char* topics[]) {
  Serial.print("Reconnect...");
  if (client.connect((uuid+WiFi.macAddress).c_str(),"murat" ,"321")) {
    // Once connected, publish an announcement...
    // ... and resubscribe
    
    for (int i = 0; i < 4; i++) {
      String topicName = String(topics[i]) + uuid;
      client.subscribe(topicName.c_str());
      Serial.println("Subscribed to : " + topicName);
    }
    
  }
  Serial.print("Error Code :"); Serial.println(client.state());
  return client.connected();
}
