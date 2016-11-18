#include <Ethernet.h>
/* -------------------------------------------------------------------------/
 * Titile:                                                     
 * Author: Jason Ghiraldini                                         
 * -------------------------------------------------------------------------/
 */

byte mac[] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x01 }; // MAC address made up
byte ip[] = { 192, 168, 10, 86 }; // Subnet Mask 255.255.255.0
// Default Gateway 192.168.10.1                                 
int analogPin = 0;                 // Analog input from detector
double detector_value = 0;

Server server(80);              // 10001 = made up port

void setup(){
  Serial.println("Setting up");
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
  analogReference(DEFAULT); // Default = 5V  ?
}

void loop(){
  //  Serial.println("Read Analog Channel 0"); // Range of detector voltage output 0 - 500mV
  //  stream_data();
  Client client = server.available();
  if (client){
    int response; //-------------------------------TCP input from LV side
    //  Serial.flush();
    response = client.read(); //-------------------Read LV string
    Serial.println(analogRead(analogPin));
    server.write(analogRead(analogPin));

    if (response == 3){//-------------------------------------Default value from TCP or Ping from LV?
      //   Serial.flush();
      response = client.read(); //-------------------Read LV string

      server.write("Connected");//---------------Send ack to LV
      Serial.print("Response from LabVIEW: ");
      Serial.println(response);
    }
    if (response == 99){
      //    Serial.flush();
      response = client.read(); //-------------------Read LV string

      Serial.println("Streaming to lv");
      //-------------------------------------Value LV will send when ready to view spectrum
      Serial.flush();//----------------------------Clear values before sending over TCP
      server.write(analogRead(analogPin));
      Serial.println(analogRead(analogPin));
    }

  }
}
//void stream_data(){

//}









