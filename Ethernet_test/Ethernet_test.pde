#include <Ethernet.h>
/* -------------------------------------------------------------------------/
 * Titile:                                                     
 * Author: Jason Ghiraldini                                         
 * -------------------------------------------------------------------------/
 */

byte mac[] = { 
  0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x01 }; // MAC address made up
byte ip[] = { 
  192, 168, 10, 200 }; // Subnet Mask 255.255.255.0
// Default Gateway 192.168.10.1                                 
int analogPin = 0;                // Analog input from detector
double detector_value = 0;

Server server = Server(80);              // 10001 = made up port

void setup(){
  Ethernet.begin(mac, ip);
  server.begin();
  analogReference(INTERNAL); // Default = 5V, Internal = 1.1V
}

void loop(){
  Client client = server.available();
  while(client == true){
    server.println(analogRead(analogPin));
    delay(.01);
  }
}






