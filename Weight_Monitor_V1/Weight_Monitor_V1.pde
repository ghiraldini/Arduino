#include <Ethernet.h>
#include <EEPROM.h>
/* -------------------------------------------------------------------------/
 * Titile: Weight Monitor                                                   /
 * Author: Jason Ghiraldini                                                 /
 * ES 485: Wireless Communications and Networks                             /
 *
 * Web Server that is taken out of sleep mode when scale is stepped on to.  /
 * Scale reading(s) are saved to EEPROM.                                    /
 * LabVIEW Client requests connection to server.                            /
 * LabVIEW Client requests scale readings from server.                      /
 * When all readings are sent to Client, everything is erased.              /
 * Arduino goes back to sleep until next weigh in.                          /
 * -------------------------------------------------------------------------/
 */

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // MAC address and IP address, change if necessary
byte ip[] = { 130, 157, 73, 200 };

int inputPIN = 0; // ADC input from scale
int response; 
int value[30]; // array to save weights
int i = 0;
  
Server server(10001); // 10001 = made up port

void setup(){
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
}

void loop(){
  analogReference(EXTERNAL);// AREF is set to voltage applied to pin (~310 mV)
  Client client = server.available();
  //------------------------------Read scale reading and save to EEPROM-----------------------------------
  while(value[i] != value[i-1]){
  value[i] = analogRead(inputPIN);
  i++;
  }
  EEPROM.write(i,value[i]);
  //------------------------------LabVIEW Client Requests Connection to Server----------------------------
  response = client.read();
  switch(response){
  case -1: // LabVIEW is connecting to server, but not getting readings
    server.println("Connected");
    Serial.println(response);
    delay(250);
    break;
    //-----------------------------LabVIEW is connected and pings for readings------------------------------
  case 57: // LabVIEW is connected and pings for weigh in readings
    //server.println(i); // send number of weigh ins first
    Serial.println(response);
    if(i == 0){
      server.print("No Data");
    }
    for(int j = 0; j < i+1; j++){
      EEPROM.read(j);  // read value stored in EEPROM
      delay(1000);
      server.println(value[j]); // send readings
      Serial.println(value[j]);
      delay(1000);
    }
    server.println("DONE"); // Tell Client all readings have been sent          
    i = 0;
    break;
  }
}





