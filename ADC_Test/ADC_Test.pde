#include <Ethernet.h>
#include <EEPROM.h>
/* -------------------------------------------------------------------------/
 * Titile: Weight Monitor                                                   /
 * Author: Jason Ghiraldini                                                 /
 * ES 485: Wireless Communications and Networks                             /
 *                                                                          /
 * Web Server that is taken out of sleep mode when scale is stepped on to.  /
 * Scale reading(s) are saved to EEPROM.                                    /
 * LabVIEW Client requests connection to server.                            /
 * LabVIEW Client requests scale readings from server.                      /
 * When all readings are sent to Client, everything is erased.              /
 * Arduino goes back to sleep until next weigh in.                          /
 * -------------------------------------------------------------------------/
 */

byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // MAC address and IP address, change if necessary
byte ip[] = { 
  130, 157, 73, 200 };

int inputPIN = 1; // ADC input from scale
int response; 
int i = 0;
int index = 0;
double voltage = 0;
double weight = 0;
double value = 0; // array to save weights
unsigned long time = 30000;
double sensorValue = 0;
double sensorMin = 1023;  // minimum sensor value
double sensorMax = 0;     // maximum sensor value
double sum = 0;
double difference = 0;

Server server(10001); // 10001 = made up port

void setup(){
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
  analogReference(DEFAULT);// AREF is set to voltage applied to pin (~322mV if 9V) || (~319mV if USB)
}

void loop(){

  Client client = server.available();
  //------------------------------Read scale reading and save to EEPROM-----------------------------------

  Serial.println("Beginning Caliberation");
  delay(2000);
  while(1){
    int timer = millis();
    sensorValue = analogRead(inputPIN);
    delay(200);
    if (sensorValue > sensorMax) {
      sensorMax = sensorValue;
    }
    if (sensorValue < sensorMin) {
      sensorMin = sensorValue;
    }
    if(timer > time){
      Serial.println("TIMEOUT");
      break;
    }
    i++;
  }

  Serial.print("MAX: ");
  Serial.println(sensorMax);
  Serial.print("MIN: ");
  Serial.println(sensorMin);
  delay(1000);
  difference = ((sensorMax - sensorMin)/205)*1000;
  weight = .8372*difference - 17.888;
  Serial.print("Weight: ");
  Serial.println(weight);
  Serial.println();
  Serial.print("Difference in Voltage: ");
  Serial.println(difference);

  delay(15000);

  index++;
  EEPROM.write(i,weight);//------------------------Save weight to EEPROM---------------------------------------------------
  EEPROM.write(255, i);//--------------------------Save pointer of number of weigh ins-------------------------------------

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















