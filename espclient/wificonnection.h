#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wifiClient;
PubSubClient client(wifiClient);
const char* ssid = "A52S"; const char* pass = "12345678";
IPAddress server(192, 168, 6, 205);



void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i=0;i<length;i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println(); // 
}


bool publishData(char* topic, float sensorData, float threshold, boolean stat){

  char topicData[50];
  
  sprintf(topicData,"%f/%f/%d",sensorData,threshold,stat);
  return client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
}

bool publishData(char* topic, int sensorData, int threshold, boolean stat){

  char topicData[50];
  
  sprintf(topicData,"%d/%d/%d",sensorData,threshold,stat);
  return client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
}

boolean reconnect(char* topics[]) {
  Serial.println("Reconnect...");
  if (client.connect("arduinoClient")) {
    // Once connected, publish an announcement...
    // ... and resubscribe
    for (int i = 0; i< 4;i++){
      client.subscribe(topics[i]);
    }
  }
  return client.connected();



  
  // Loop until we're reconnected
//  while (!client.connected()) {
//    Serial.print("Attempting MQTT connection...");
//    // Attempt to connect
//    if (client.connect("arduinoClient")) {
//      Serial.println("connected");
//      // Once connected, publish an announcement...
//      client.subscribe("inTopic");
//      client.publish("inTopic","hello world");
//      // ... and resubscribe
//      
//    } else {
//      Serial.print("failed, rc=");
//      Serial.print(client.state());
//      Serial.println(" try again in 5 seconds");
//      // Wait 5 seconds before retrying
//      delay(5000);
//    }
//  }
}

void setup_wifi() {
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

void setupMQTT() {
  setup_wifi();
  client.setServer(server, 1883);
  client.setCallback(callback);
  delay(1500);
}
