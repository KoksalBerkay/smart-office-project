#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wifiClient;
PubSubClient client(wifiClient);
IPAddress server(192, 168, 43, 57);



void callback(char* topic, byte* payload, unsigned int length);


bool publishData(char* topic, float sensorData, float threshold, boolean stat){

  char topicData[50];
  bool ret;
  
  sprintf(topicData,"%f/%f/%d",sensorData,threshold,stat);

  client.unsubscribe(topic);
  ret = client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
  client.subscribe(topic);
  return ret;
}

bool publishData(char* topic, int sensorData, int threshold, boolean stat){

  char topicData[50];
  bool ret;
  
  sprintf(topicData,"%d/%d/%d",sensorData,threshold,stat);
  
  client.unsubscribe(topic);
  ret= client.publish(topic, topicData); // AX0 AX1 AX2 AX4 AX5 AX6 AX7 AX8
  client.subscribe(topic);

  return ret;
}


boolean reconnect(char* topics[]) {
  Serial.print("Reconnect...");
  if (client.connect("arduinoClient")) {
    // Once connected, publish an announcement...
    // ... and resubscribe
    for (int i = 0; i< 4;i++){
      client.subscribe(topics[i]);
    }
  }

  Serial.print("Error Code :"); Serial.println(client.state());

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

void setup_wifi(const char* ssid ,const char* pass) {
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

void setupMQTT(String ssid ,String pass) {
  setup_wifi(ssid.c_str() ,pass.c_str());
  client.setServer("192.168.43.57", 1883);
  client.setCallback(callback);
  delay(1500);
}
