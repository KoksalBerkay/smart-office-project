#include <DHT.h>
#include "wificonnection.h"
#include "pair.h"
#define PIR_SENSOR 15
#define DHT_PIN 5
#define LDR_PIN 34
#define RELAY_PIN 18
#define LIGHT_PIN 19
#define SERVER_IP "192.168.1.97"
#define SERVER_PORT 1883
#define ESPBUTTON 0
#define LIGHTTOPIC "sensor-data\\light\\"
#define MOTIONTOPIC "sensor-data\\motion\\"
#define TEMPTOPIC "sensor-data\\temp\\" 
#define HUMIDTOPIC "sensor-data\\humidity\\"

DHT dht(DHT_PIN, DHT11);

MqttHandler handler;
String uuid;
String mqttPass;
int pirData;
int lightData;
int lightThreshold = 500;
unsigned int lastReconnectAttempt = 0;
unsigned int lastMotionTime = 0;
unsigned int motionlessTimeThreshold = 0;
float tempData;
float tempThreshold = 26;
float humidityData;


char* topics[] = {"temp", "light", "motion", "humidity"};

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("Data from MQTT recieved.");
  char* d = (char*)malloc(length + 1);
  d = (char*)payload; d[length] = 0;
  String data(d);
  Serial.println(data);

  // THRESHHOLD
  if (data.charAt(0) == 'T') {
    String thresStr = data.substring(1);
    if (!strcmp(topic , String(TEMPTOPIC + uuid).c_str())) {
      tempThreshold = thresStr.toFloat();
      Serial.println("Temp threshold updated. Updated value = " + String(tempThreshold));
    }
    else if (!strcmp(topic , String(LIGHTTOPIC + uuid).c_str())) {
      lightThreshold = thresStr.toInt();
      Serial.println("Light threshold updated. Updated value = " + String(lightThreshold));
    }
    else if (!strcmp(topic , String(MOTIONTOPIC + uuid).c_str())) {
      motionlessTimeThreshold = thresStr.toInt();
      Serial.println("Motion threshold updated. Updated value = " + String(lightThreshold));
    }
  }

  Serial.print("Recived Data : ");
  Serial.println(data);

}

void loop2( void * parameter){
  while(1){
    client.loop();
    delay(10);
    }
}

void setup() {
  pinMode(PIR_SENSOR, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(DHT_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LIGHT_PIN, OUTPUT);
  Serial.begin(115200);


  String ssid;
  String pass;


  Serial.println("Pairing");
  Pair(&ssid , &pass , &uuid, 0);

  Serial.println("Pairing done");
  Serial.println("SSID : " + ssid);
  Serial.println("Pass : " + pass);
  Serial.println("UUID : " + uuid);
  dht.begin();
  Serial.println("setup done");
  handler.setUuid(uuid);
  handler.setServerIP(SERVER_IP);
  handler.setPort(SERVER_PORT);
  handler.setWifiPass(pass);
  handler.setWifiSsid(ssid);
  handler.setupWifi();
  handler.setupMQTT(callback);
  client.setCallback(callback);
  TaskHandle_t Task1;
  xTaskCreatePinnedToCore(
      loop2, /* Function to implement the task */
      "Task1", /* Name of the task */
      10000,  /* Stack size in words */
      NULL,  /* Task input parameter */
      0,  /* Priority of the task */
      &Task1,  /* Task handle. */
      1); /* Core where the task should run */
  delay(500);
}



void loop() {


  pirData = digitalRead(PIR_SENSOR);
  lightData = analogRead(LDR_PIN);
  tempData = dht.readTemperature();
  humidityData = dht.readHumidity();

  Serial.print("PIR Sensor : ");
  Serial.println(pirData);
  Serial.print("LDR : ");
  Serial.println(lightData);
  Serial.print("Temp : ");
  Serial.println(tempData);
  Serial.print("Hmdy : ");
  Serial.println(humidityData);
  //digitalWrite(RELAY_PIN, pirData);



  lastMotionTime = pirData ? millis() : lastMotionTime;
  int motionlessTime = millis() - lastMotionTime;
  Serial.print("motionless time : ");
  Serial.println(motionlessTime);
  
  digitalWrite(RELAY_PIN , (tempData < tempThreshold) ? 1 : 0);

  digitalWrite(LIGHT_PIN , (lightData < lightThreshold) ? 1 : 0);



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

    handler.publishData((TEMPTOPIC + uuid).c_str(), tempData, tempThreshold, digitalRead(RELAY_PIN));
    Serial.println(tempThreshold);
    //publishData("temp", 22, 25, true);
    handler.publishData((MOTIONTOPIC + uuid).c_str() , motionlessTime / 1000 , motionlessTimeThreshold , pirData);
    handler.publishData((LIGHTTOPIC + uuid).c_str() , lightData , lightThreshold, (lightData < lightThreshold));
    handler.publishData((HUMIDTOPIC + uuid).c_str() , humidityData , 0, 0);

    delay(100);
    if (digitalRead(ESPBUTTON) == 0) {
      clearFlash();
    }

    
  }


  delay(100);
}
