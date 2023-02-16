#include <SoftwareSerial.h>

String AP ="esp32"; 
String PASS ="12345678"; 
String HOST = "192.168.4.1";
String PORT = "80";

int countTimeCommand; 
boolean found = false; 
SoftwareSerial esp8266(8,9); 
 
String Data ="";
void setup() {
  Serial.begin(9600);
  esp8266.begin(9600);
  sendCommand("AT",5,"OK",false);
  
  delay(1000);
  esp8266.end();
  esp8266.begin(9600);
  ConnectToWifi();
  sendCommand("AT+CIPMUX=1",5,"OK",false);

  pinMode(A0, INPUT);
}

int httpReq(int connectionID,String uri,String hostIP){

  String httpHeader=
  "GET " + uri + " HTTP/1.0\n" +
  "Host: " + hostIP + "\n" +
  "Accept: application/json\n" +
  "Content-Type: application/json\n" +
  "Connection: Keep-Alive\n" +
  "\n";

  
  sendCommand("AT+CIPSTART=4,\"TCP\",\""+ HOST +"\","+ PORT,15,"OK",false);

  sendCommand("AT+CIPSEND=4," +String(httpHeader.length()+4),4,">",false);
    
  sendCommand(httpHeader,20,"OK",true);
    

  return true;
}

bool ledStat;

void loop(){

  int ldr = analogRead(A0);

  Serial.println(ldr);
  
  if(ldr < 600)
    ledStat = 0;
  else
    ledStat = 1;

  if (ledStat == true)
    httpReq(4,"/H",HOST);
  if (ledStat == false)
    httpReq(4,"/L",HOST);
}

bool ConnectToWifi(){
  for (int a=0; a<15; a++)
  {
    sendCommand("AT",5,"OK",false);
    sendCommand("AT+CWMODE=1",5,"OK",false);
    boolean isConnected = sendCommand("AT+CWJAP=\""+ AP +"\",\""+ PASS +"\"",20,"OK",false);
    if(isConnected)
    {
      return true;
    }
  }
}

bool sendCommand(String command, int maxTime, char readReplay[],boolean isGetData) {
  boolean result=false;

  //Test Purpose
  Serial.print("=> ");
  Serial.print(command);
  Serial.print(" ");
  while(countTimeCommand < (maxTime*1))
  {
    esp8266.println(command);
    if(esp8266.find(readReplay))//ok
    {   
      if(isGetData)
      {      
        if(esp8266.find(readReplay))
        {
          Serial.println("Success : Request is taken from the server");
        }
        while(esp8266.available())
        {
            char character = esp8266.read();
            Data.concat(character); 
            if (character == '\n')
             {
             Serial.print("Received: ");
             Serial.println(Data);
             delay(50);
             Data = "";
        } 
        }         
      }
      result = true;
      break;
    }
    countTimeCommand++;
  }
  
  if(result == true)
  {
    Serial.println("Success");
    
    countTimeCommand = 0;
  }
  
  if(result == false)
  {
    Serial.println("Fail");
    Serial.println("-------------------------------------------");
    countTimeCommand = 0;
  }
  
  found = false;
  return result;
 }
