#include <XBee.h>
XBee xbee = XBee();

//unsigned long start = millis();

// allocate two bytes for to hold a 10-bit analog reading
uint8_t payload[] = {"1234567891011121314151617181920"};

// with Series 1 you can use either 16-bit or 64-bit addressing

// 16-bit addressing: Enter address of remote XBee, typically the coordinator
//Tx16Request tx = Tx16Request(0x5678, payload, sizeof(payload));

// 64-bit addressing: This is the SH + SL address of remote XBee
XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);
// unless you have MY on the receiving radio set to FFFF, this will be received as a RX16 packet
Tx64Request tx = Tx64Request(addr64, payload, sizeof(payload));

TxStatusResponse txStatus = TxStatusResponse();

void setup() {
  xbee.begin(9600);
  Serial.begin(9600);
}

void loop() {

  // start transmitting after a startup delay.
    delay(10000);
    xbee.send(tx);
    Serial.print("sent"); 
  // after sending a tx request, we expect a status response
  // wait up to 5 seconds for the status response
  if (xbee.readPacket(5000)) {
    // got a response!

    // should be a znet tx status            	
    if (xbee.getResponse().getApiId() == TX_STATUS_RESPONSE) {
      xbee.getResponse().getZBTxStatusResponse(txStatus);
    }
  }
  delay(1000);
}

