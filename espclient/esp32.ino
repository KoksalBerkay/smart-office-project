#include <DHT.h>
#include "wificonnection.h"

#define PIR_SENSOR 13
#define DHT_PIN 2
#define relayPin 12
#define LDR_PIN 15

char* topics[] = {"temp", "light", "motion", "humidity"};

DHT dht(DHT_PIN,DHT11);
int pirData;
float tempData;
float tempThreshold = 26;
int lightData;

int lastReconnectAttempt = 0;

void setup() {
  pinMode(PIR_SENSOR, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(DHT_PIN, INPUT);
  pinMode(relayPin, OUTPUT);
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
  digitalWrite(relayPin, pirData);

  
 
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
 
    publishData("temp", tempData, tempThreshold, true);
    

    
    
    client.loop();
  }
  




  

  

}
