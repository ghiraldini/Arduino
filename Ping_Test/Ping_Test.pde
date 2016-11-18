#include <XBee.h>
XBee xbee = XBee();
// allocate two bytes for to hold a 10-bit analog reading
uint8_t payload[] = {2};
// 64-bit addressing: This is the SH + SL address of remote XBee
XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);//(900MHz Radios)
// unless you have MY on the receiving radio set to FFFF, this will be received as a RX16 packet
Tx64Request tx = Tx64Request(addr64, payload, sizeof(payload));
TxStatusResponse txStatus = TxStatusResponse();

void setup() {
  xbee.begin(9600);
  Serial.begin(9600);
  Serial3.begin(9600);
}

void loop() {
  // start transmitting after a startup delay.
  if(Serial.available()){
    int incomingByte = Serial.read();
    if (incomingByte == '1'){
      delay(10000);
      xbee.send(tx);
      Serial.println("Sent Data");
      Serial3.flush();
      delay(5000);
      while (Serial3.available()){
        byte input = Serial3.read();
        Serial.print(input);
      }
      delay(1000);
    }
  }
}

