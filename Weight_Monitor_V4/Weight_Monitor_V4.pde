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
int LED = 8; // LED status of server

int index;

double reading;
double weight = 0;
double sensorValue = 0;
double sensorMin = 1023;  // minimum sensor value
double sensorMax = 0;     // maximum sensor value
double sum = 0;
double difference = 0;


unsigned long time = 30000; // Timeout for weight
unsigned long time2 = 45000; // Timeout for weight

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
}

void get_weight(){

  unsigned long timer = millis();
  unsigned long elapsed_time = 0;

  Serial.println("Step on Scale in the next 30 seconds");
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
  weight = 0;
  sensorValue = 0;
  sensorMin = 1023;  // minimum sensor value
  sensorMax = 0;     // maximum sensor value
  sum = 0;
  difference = 0;

}


void check_client(){
  Client client = server.available();
  int response; 
  //-----------------------------------------------LabVIEW Client Requests Connection to Server----------------------------
  unsigned long timer = millis();
  unsigned long elapsed_time = 0;
  Serial.flush();
  while(1){
    //    delay(100);
    response = client.read();
    switch(response){
      delay(200);
    case -1:
      server.println("Connected");
      Serial.print("Response from LabVIEW: ");
      Serial.println(response); // input from TCP
      delay(150);
      break;
    case 57: //--------------------------------------LabVIEW is connecting to server, but not getting readings---------------
      Serial.print("Serial Input: ");
      Serial.println(response);
      //      delay(100);
      //      break;
      //---------------------------------------------LabVIEW is connected and pings for readings------------------------------

      index = EEPROM.read(255);
      if(index == 0){
        server.println("NO DATA");
        //        server.println("DONE");
        break;
      }
      else{
        for(int j = 1; j < index+1; j++){
          reading = EEPROM.read(j);  // read value stored in EEPROM
          delay(1000);
          server.println(reading); // send readings
          Serial.println(reading); // print readings to serial monitor
          delay(1000);
        }
        server.println("DONE"); // Tell Client all readings have been sent          
        EEPROM.write(255, 0);
        break;
      }
    }
    elapsed_time = millis() - timer;
    if(elapsed_time > time2){
      Serial.println("TIMEOUT");
      break;
    }
  }
} 














