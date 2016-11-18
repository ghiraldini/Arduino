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

byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // MAC address and IP address, change if necessary
byte ip[] = { 
  130, 157, 73, 200 };

int inputPIN = 1; // ADC input from scale
int LED = 8; // LED status of server

int response; 
int i = 0;
int index;

double reading;
double weight = 0;
double sensorValue = 0;
double sensorMin = 1023;  // minimum sensor value
double sensorMax = 0;     // maximum sensor value
double sum = 0;
double difference = 0;

unsigned long time = 30000; // Timeout for weight

Server server(10001); // 10001 = made up port

void setup(){
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
  analogReference(DEFAULT);
  pinMode(LED, OUTPUT);
  EEPROM.write(255, 0);
}

void loop(){
  Serial.println("Getting weight");
  get_weight();
  Serial.println("Checking Client");
  check_client();
  delay(15000);
  Serial.println("Reading EEPROM");
  delay(2000);
  index = EEPROM.read(255);
  Serial.print("Index: ");
  Serial.println(index);
  if(index == 0){
    server.print("No Data");
  }
  else{
    for(int j = 1; j < index+1; j++){
      reading = EEPROM.read(j);  // read value stored in EEPROM
      delay(1000);
      server.println(reading); // send readings
      Serial.println(reading); // print readings to serial monitor
      delay(1000);
    }
  }
}

void get_weight(){
  unsigned long timer = millis();
  unsigned long elapsed_time = 0;

  Serial.println("Beginning Calibration");
  while(1){
    digitalWrite(LED, HIGH);
    Serial.print("Elapsed Time: ");
    Serial.println(elapsed_time);
    sensorValue = analogRead(inputPIN);
    delay(200);
    if (sensorValue > sensorMax) {
      sensorMax = sensorValue;
    }
    if (sensorValue < sensorMin) {
      sensorMin = sensorValue;
    }
    elapsed_time = millis() - timer;
    if(elapsed_time > time){
      Serial.println("TIMEOUT");
      break;
    }
  }
  digitalWrite(LED, LOW);
  //-----------------------------------Turn value of 0 - 1023 into a voltage then weight in lbs-----------------------------
  Serial.print("MAX: ");
  Serial.println(sensorMax);
  Serial.print("MIN: ");
  Serial.println(sensorMin);
  delay(1000);
  difference = ((sensorMax - sensorMin)/205)*1000;
  weight = .8372*difference - 17.888;
  Serial.print("Weight: ");
  Serial.println(weight);
  Serial.print("Difference in Voltage: ");
  Serial.println(difference);
  delay(3000);
  if(weight >= 50 && weight <= 250){
    index++;
    EEPROM.write(index, weight);//------------------------Save weight to EEPROM---------------------------------------------------
    EEPROM.write(255, index);//--------------------------Save pointer of number of weigh ins-------------------------------------
    Serial.print("Saved to EEPROM at Index = ");
    Serial.println(index);
    
  }
}

void check_client(){
  Client client = server.available();
  //-----------------------------------------------LabVIEW Client Requests Connection to Server----------------------------
  response = client.read();
  switch(response){
  case -1: //--------------------------------------LabVIEW is connecting to server, but not getting readings---------------
    server.println("Connected");
    Serial.print("Serial Input: ");
    Serial.println(response);
    delay(250);
    break;
    //---------------------------------------------LabVIEW is connected and pings for readings------------------------------
  case 57:
    Serial.println(response); // input from TCP
    i = EEPROM.read(255);
    if(i == 0){
      server.print("No Data");
    }
    for(int j = 1; j < i+1; j++){
      weight = EEPROM.read(j);  // read value stored in EEPROM
      delay(1000);
      server.println(weight); // send readings
      Serial.println(weight); // print readings to serial monitor
      delay(1000);
    }
    server.println("DONE"); // Tell Client all readings have been sent          
    i = 0;
    EEPROM.write(255, i);
    break;
  }
} 









