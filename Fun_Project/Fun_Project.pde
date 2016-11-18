#include <Ethernet.h>

byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // MAC address and IP address, change if necessary

byte ip[] = {204, 96, 172, 200};

int LED = 8; // LED status of server

Server server(10001); // 10001 = made up port

void setup(){
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  server.begin();
  pinMode(LED, OUTPUT);
}

void loop(){
  Client client = server.available();
  byte response = client.read();
  Serial.print("Input: ");
  Serial.println(response);
}

