#include <DHT.h>
#include "wificonnection.h"
#include "pair.h"
#define PIR_SENSOR 4
#define DHT_PIN 5
#define LDR_PIN 15
#define RELAY_PIN 18
#define LIGHT_PIN 19

MqttHandler handler;


char* topics[] = {"temp", "light", "motion", "humidity"};

DHT dht(DHT_PIN, DHT11);

int pirData;
int motionlessTimeThreshold = 600000;
float tempData;
float tempThreshold = 26;
int lightData;
int lightThreshold = 500;


int lastReconnectAttempt = 0;
int lastMotionTime = 0;
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("Data from MQTT recieved.");
  char* d = (char*)malloc(length + 1);
  d = (char*)payload; d[length] = 0;
  String data(d);

  String valueStr = data.substring(0 , data.indexOf('/'));
  String thresStr = data.substring(data.indexOf('/') + 1 , data.indexOf('/', data.indexOf('/') + 1));
  String statStr = data.substring(data.lastIndexOf('/') + 1);

  Serial.print("Topic : ");
  Serial.print(topic);
  Serial.print(" , Thres : ");
  Serial.print(thresStr.toInt());
  Serial.print(" , Recived Data : ");
  Serial.println(data);

  if (!strcmp(topic , "temp")) {
    tempThreshold = thresStr.toFloat();

  }
  else if (!strcmp(topic , "light")) {
    lightThreshold = thresStr.toInt();
  }
  else if (!strcmp(topic , "motion")) {
    motionlessTimeThreshold = thresStr.toInt();
  }
}


void setup() {
  pinMode(PIR_SENSOR, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(DHT_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);


  String ssid;
  String pass;
  String uuid;

  Serial.println("Pairing");
  Pair(&ssid , &pass , &uuid, 1);

  Serial.println("Pairing done");
  Serial.println("SSID : " + ssid);
  Serial.println("Pass : " + pass);
  Serial.println("UUID : " + uuid);
  dht.begin();
  Serial.println("setup done");
  handler.setUuid(uuid);
  handler.setServerIP("192.168.43.254");
  handler.setPort(1883);
  handler.setWifiPass(pass);
  handler.setWifiSsid(ssid);
  handler.setupWifi();
  handler.setupMQTT(callback);
}



void loop() {


  pirData = digitalRead(PIR_SENSOR);
  lightData = analogRead(LDR_PIN);
  tempData = dht.readTemperature();

  Serial.print("PIR Sensor : ");
  Serial.println(pirData);
  Serial.print("LDR : ");
  Serial.println(lightData);
  Serial.print("DHT : ");
  Serial.println(tempData);
  //digitalWrite(RELAY_PIN, pirData);



  lastMotionTime = pirData ? millis() : lastMotionTime;
  int motionlessTime = millis() - lastMotionTime;

  digitalWrite(RELAY_PIN , tempData < tempThreshold ? 1 : 0);

  digitalWrite(LIGHT_PIN , (lightData < lightThreshold) && (motionlessTime < motionlessTimeThreshold) ? 1 : 0);



  if (!client.connected()) {
    long now = millis();
    if (now - lastReconnectAttempt > 5000) {
      lastReconnectAttempt = now;
      // Attempt to reconnect
      if (handler.reconnectTopics(topics)) {
        lastReconnectAttempt = 0;
      }
    }
  } else {
    // Client connected
    String topicName = "temp" + uuid;
    Serial.println("Connecting topic name -> " + topicName);
    handler.publishData(topicName.c_str(), tempData, tempThreshold, true);
    Serial.println(tempThreshold);
    //publishData("temp", 22, 25, true);
    //publishData("motion" ,motionlessTime ,motionlessTimeThreshold ,true);
    //publishData("light" ,lightData ,lightThreshold, true);

    delay(1000);


    client.loop();
  }


  delay(100);
}
