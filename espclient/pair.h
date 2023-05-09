#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <string>
#include "uuidgen.h"

using namespace std;

#define MANUFACTURER_NAME "KBMG"
#define SERVICE_UUID "c2302aa0-0548-49ff-a10a-e421fdb311ff"
#define CHARACTERISTIC_SSID_UUID "4934c8ce-bce0-417c-b613-14f9f24da803"
#define CHARACTERISTIC_PASS_UUID "7dec32af-0afe-4718-9c5b-a0c120bab609"
#define CHARACTERISTIC_UUID_UUID "e91a0da9-9048-4b87-99a9-01a8a62b65bf"
#define ESP_FLASH_NAME "espflash"
#define FLASH_WIFI_PASS "wifiPass"
#define FLASH_WIFI_SSID "wifiSsid"
#define FLASH_WIFI_UUID "uuid"


String wifiPass;
String wifiSsid;
String uuid;
Preferences pref;


bool writeStringToFlash(String key, String value) {
  size_t valueSize = strlen(key.c_str());
  
  pref.remove(key.c_str());
  size_t writtenSize = pref.putString(key.c_str(), value);
  
  Serial.println("String saved into flash.");
  return valueSize == writtenSize ? true : false;
}


class CharacteristicCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
      String characterData(pCharacteristic->getValue().c_str());
      if (!pCharacteristic->getUUID().toString().compare(CHARACTERISTIC_SSID_UUID)) {
        wifiSsid = characterData;
        Serial.print("SSID RECV. -> ");
        Serial.println(characterData);
      }
      else if (!pCharacteristic->getUUID().toString().compare(CHARACTERISTIC_PASS_UUID)) {
        wifiPass = characterData;
        Serial.print("PASS RECV. -> ");
        Serial.println(characterData);

      } else {
        Serial.println("DATA RECIEVED BUT NOT FROM ONE OF THE WIFI CRED. CHARACTERISTICS. ==>\n" + String(pCharacteristic->getUUID().toString().c_str()));
      }
    }
};

class ServerCallback : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println("Client connected.");
      BLEDevice::stopAdvertising();
    }
    void onDisconnect(BLEServer* pServer) {
      Serial.println("Client disconnected.");
      BLEDevice::startAdvertising();
      
    }
};

void startBluetooth() {

  BLEDevice::init("test_esp");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallback());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *ssidCharacteristic = pService->createCharacteristic(
                         CHARACTERISTIC_SSID_UUID,
                         BLECharacteristic::PROPERTY_WRITE);
  BLECharacteristic *passCharacteristic = pService->createCharacteristic(
                  CHARACTERISTIC_PASS_UUID,
                  BLECharacteristic::PROPERTY_WRITE);
  BLECharacteristic *uuidCharacteristic = pService->createCharacteristic(
                  CHARACTERISTIC_UUID_UUID,
                  BLECharacteristic::PROPERTY_READ);

  uuid = StringUUIDGen();
  uuidCharacteristic->setValue(string(uuid.c_str())); 
  Serial.println("UUID -> " + uuid);
  ssidCharacteristic->setCallbacks(new CharacteristicCallback());
  passCharacteristic->setCallbacks(new CharacteristicCallback());
  
  BLEAdvertisementData advertisementData;
  advertisementData.setManufacturerData(MANUFACTURER_NAME);
  advertisementData.setName("test_esp");
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setScanResponseData(advertisementData);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  pService->start();
  BLEDevice::startAdvertising();
  delay(2000);
}



void clearFlash() {
  pref.begin(ESP_FLASH_NAME, false);
  pref.clear();
  pref.end();
}


void Pair(String* ssid ,String* pass ,String* UUID ,bool reseteeprom = false ,unsigned int timeOut = -1) {

  pref.begin(ESP_FLASH_NAME);
  int time = millis();
  
  if(!reseteeprom){
    wifiSsid = pref.getString(FLASH_WIFI_SSID, "");
    wifiPass = pref.getString(FLASH_WIFI_PASS, "");
    uuid = pref.getString(FLASH_WIFI_UUID, "");
  }


// mfmfmf2020!

  if (wifiSsid == 0 || wifiPass == 0 || uuid == 0) {
    
    startBluetooth();
    while ((wifiSsid == 0 || wifiPass == 0) && (millis() - time) < timeOut) {                                                                                                                                                                                                                                                                                                                                                           
      delay(50);
      
    }
    
    writeStringToFlash(FLASH_WIFI_SSID, wifiSsid);
    writeStringToFlash(FLASH_WIFI_PASS, wifiPass);
    writeStringToFlash(FLASH_WIFI_UUID, uuid);

  }

  delay(100);
  BLEDevice::stopAdvertising();
  BLEDevice::deinit();
  pref.end();

  *ssid = wifiSsid;
  *pass = wifiPass;
  *UUID = uuid;
}
