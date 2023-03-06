#include <SoftwareSerial.h>// ---- FOR UNO
SoftwareSerial esp(10,11); //---- FOR UNO 
// ALSO CHANGE 'Serial2' AS 'esp' FOR UNO
#define LDR A0
#define LED 9
const String ssid = "esp32";
const String password = "1245678";
const String HOST = "192.168.4.1";
const String PORT = "80";
bool ledStatusESP = false;
bool ledStatusARD = false;
int ldrRaw;

void setConfiguration(String commandLine, char* doneMessage = "OK") {
  esp.println(commandLine);
  while(!esp.find(doneMessage)){
    Serial.println("Configuring... " + commandLine);
    esp.println(commandLine); 
  }
  Serial.print("Configured -> "); Serial.println(commandLine); 
}


void setup() {
  pinMode(LDR, INPUT);
  pinMode(LED, OUTPUT);
  esp.begin(9600);
  Serial.begin(9600);
  delay(100);
  setConfiguration("AT");
  setConfiguration("AT+CWMODE=1");
  setConfiguration(String("AT+CWJAP=\"") + ssid + "\",\"" + password + "\"");
  Serial.println("Aga Baglanildi.");
  setConfiguration("AT+CIPMUX=1");
}

bool httpReq(int connectionID, String URI, char* doneMessage = "OK", String hostIP = HOST, String PORT = PORT) {
  String httpHeader=
  "GET " + URI + " HTTP/1.0\n" +
  "Host: " + hostIP + "\n" +
  "Accept: application/json\n" +
  "Content-Type: application/json\n" +
  "Connection: Keep-Alive\n" +
  "\n";
  setConfiguration("AT+CIPSTART=4,\"TCP\",\""+HOST+"\","+ PORT);
  setConfiguration("AT+CIPSEND=4," +String(httpHeader.length()+4), ">");
  delay(300);
  setConfiguration(httpHeader, doneMessage);
  setConfiguration("AT+CIPCLOSE=4");
  return true;
}

bool recData(int connectionID, String URI, char* doneMessage, String hostIP = HOST, String PORT = PORT){
  return httpReq(connectionID, URI, doneMessage, hostIP, PORT);
}


void loop() {

  // RECIEVING DATA FROM SERVER
  if(recData(4, "/ROFF", "XOFFX") && ledStatusARD == true){
    digitalWrite(LED, LOW);
    ledStatusARD = false;
  }
  delay(500);
  if(recData(4, "/RONN", "XONX") && ledStatusARD == false){
  digitalWrite(LED, HIGH);
  ledStatusARD = true
  ;
  }
  delay(100);
  

  //FOR LDR USAGE    
  // ldrRaw = analogRead(LDR);
  // Serial.println(ldrRaw);
  // if (ldrRaw < 600 && ledStatusESP == true){
  //   Serial.println("LED OFF");
  //   ledStatusESP = false;
  //   httpReq(4, "/L");
  // }else if (ldrRaw >= 600 && ledStatusESP == false){
  //   Serial.println("LED ON");
  //   ledStatusESP = true;
  //   httpReq(4, "/H");
  // } 


}



// UNNECESSARY ------------------------ BUT DONT DELETE ----------------------



//AT+CIPSTART=4,"TCP","192.168.4.1",80

  // setConfiguration("AT+CIPSTART="+String(connectionID)+","+"\"TCP\"+\""+hostIP+"\","+PORT);
  // setConfiguration("AT+CIPSEND"+String(connectionID)+",\"" +String(httpHeader.length()+4), ">");
  // setConfiguration(httpHeader);
  // setConfiguration("AT+CIPCLOSE="+String(connectionID));


//   21:52:58.021 -> Configured -> GET /H HTTP/1.0
// 21:52:58.053 -> Host: 192.168.4.1
// 21:52:58.053 -> Accept: application/json
// 21:52:58.086 -> Content-Type: application/json
// 21:52:58.119 -> Connection: Keep-Alive


//  long time = millis();

  // while ( time + 3000 > millis()){
  //   while (Serial2.available()){
  //     char data = Serial2.read();
  //     response += data;
  //   }
  // }

  // Serial.print(response + " < - THIS IS DATA");
/// ----------
  // if(intervalTime != 0){
  //   long int time = millis();
  //   String response = "";
  //   while( time + )

  //   }
  //   Serial.println(response + " <---- THIS IS THE DATA");
  // }
/// ----------
