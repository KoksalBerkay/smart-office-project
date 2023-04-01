#include <DHT.h>
#include "wificonnection.h"

#define PIR_SENSOR 13
#define DHT_PIN 2
#define RELAY_PIN 12
#define LDR_PIN 15

char* topics[] = {"temp", "light", "motion", "humidity"};

DHT dht(DHT_PIN,DHT11);
int pirData;
float tempData;
float tempThreshold = 26;
int lightData;

int lastReconnectAttempt = 0;

void callback(char* topic, byte* payload, unsigned int length) {

  char* d = (char*)malloc(length + 1);
  d = (char*)payload; d[length] = 0;
  String data(d);

  String valueStr = data.substring(0 ,data.indexOf('/'));
  String thresStr = data.substring(data.indexOf('/')+1 ,data.indexOf('/',data.indexOf('/')+1));
  String statStr = data.substring(data.lastIndexOf('/')+1);
  
  Serial.print("Topic : ");
  Serial.print(topic);
  Serial.print(" , Recived Data : ");
  Serial.println(data);

  if(topic == "temp"){
    tempThreshold = thresStr.toInt();
  } 
}

void setup() {
  pinMode(PIR_SENSOR, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(DHT_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(9600);
  
  setupMQTT();
  
  dht.begin();
}

void loop() {
  delay(1000);
  pirData = digitalRead(PIR_SENSOR);
  lightData = analogRead(LDR_PIN);
  tempData = dht.readTemperature();
  
  Serial.print("PIR Sensor : ");
  Serial.println(pirData);
  Serial.print("LDR : ");
  Serial.println(lightData);
  Serial.print("DHT : ");
  Serial.println(tempData);
  digitalWrite(RELAY_PIN, pirData);

  
 
  if (!client.connected()) {
    long now = millis();
    if (now - lastReconnectAttempt > 5000) {
      lastReconnectAttempt = now;
      // Attempt to reconnect
      if (reconnect(topics)) {
        lastReconnectAttempt = 0;
      }
    }
  } else {
    // Client connected
 
    //publishData("temp", tempData, tempThreshold, true);
    publishData("temp", 22, 25, true);
    

    
    
    client.loop();
  }
  


}
