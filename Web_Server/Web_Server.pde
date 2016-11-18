#include <Ethernet.h>
#include <EEPROM.h>
/* -------------------------------------------------------------------------/
 * Web Server that is taken out of sleep mode when scale is stepped on to.  /
 * Scale reading(s) are saved to EEPROM.                                    /
 * LabVIEW Client requests connection to server.                            /
 * LabVIEW Client requests scale readings from server.                      /
 * When all readings are sent to Client, everything is erased.              /
 * Arduino goes back to sleep until next weigh in.                          /
 * -------------------------------------------------------------------------/
 */

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 130, 157, 73, 200 };
int ledpin = 0;

Server server(10001);

void setup(){
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
//  pinMode(ledpin, OUTPUT);
}

void loop(){
  int response;
  int value[10];
  int i = 0;

  Client client = server.available();
//  client.flush();
//  while (1){
    //------------------------------Read scale reading and save to EEPROM-----------------------------------
//    value[i] = analogRead(0);
//    EEPROM.write(i,value[i]);
//    i++;
    value[0] = 124;
    value[1] = 126;
    value[2] = 123;
    value[3] = 45;
    value[4] = 13;
    i = 5;
    //------------------------------LabVIEW Client Requests Connection to Server----------------------------
    response = client.read();
    Serial.println(response);
    while (response != 49){ // LabVIEW is connecting to server, but not getting readings
      server.println("Connected");
      Serial.println(response);
      //digitalWrite(ledpin, HIGH);   // Blink LED
      //delay(1000);
      //digitalWrite(ledpin, LOW);
    }
    //-----------------------------LabVIEW is connected and pings for readings------------------------------

    while (response == 57){ // LabVIEW is connected and pings for weigh in readings
      int j = 0;
      Serial.println(response);
      server.println(i); // send number of weigh ins first
      while (j != i){
        //EEPROM.read(j,value[j]);  // read value stored in EEPROM
        //delay(1000);
        Serial.println(response);
        server.println(value[j]); // send readings
        Serial.println(value[j]);
        delay(1000);
        j++;
      }
      server.print("DONE..."); // Tell Client all readings have been sent
      j = 0;              
      i = 0;
    }
 }
//}


