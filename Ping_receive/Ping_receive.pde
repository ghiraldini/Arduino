int data_in_length = 20;
unsigned long maxWait = 30000;   // milliseconds to wait for data from serial port 1 
unsigned long minWait = 15000;   // milliseconds for smaller wait for serial 1 data     
byte *sDat[20];

bool waitForSerial1data() {

  unsigned long beginWait = millis();                            // record current millis for start of wait
  unsigned long elapsed = 0;                                     // elapsed time

  while(!Serial3.available()) {                                  // loop until there is data to be read or timeout
    delay(10);                                                   // A short delay to allow for forced breaks
    elapsed = millis() - beginWait;                              // calculate timeout
    if(elapsed > maxWait)                                        // exit if no serial data has arrived
      return false;                                              // no serial data has arrived
  }
  return true;                                                    // data has been detected in serial port 1
} 

// A function to check for a timeout based on global variable minWait
bool timeout( int c ) {

  if( c == START ) {
    startTime = millis();
    delay(1);
    return false;
  }

  if( c == CHECK ) {
    elapsedTime = millis() - startTime;
    if( elapsedTime > minWait ) {
      Serial.print("Elapsed = " );
      Serial.println(elapsedTime);
      return true;
    }
  }
  return false;
}  
// Here is an example of how I use the timeout function and read bytes from the serial port
// I think this could be modified to look for an XBee string with our message embedded 
// Read each menu item as received at the serial 1 buffer

bool readMenu(byte *sDat, int sDatLen) {                      // General serial read routine for SWCA port

  byte rcvByte = 0x0;                                         // var to hold each byte value from serial buffer
  wipeS1data();                                               // clear array to hold received data from serial buffer

  if(waitForSerial3data()) {                                  // hangout till serial data arrives
    timeout(START);
    do {                                                      // Look for first flag  
      if(timeout(CHECK)) {                                   // prevent endless loop if no data arrives
        timeout(STOP);
        return false;
      }
    } 
    while(rcvByte != 0x7E);                                 // Read bytes until start delimeter is found

    for(int i = 0; i < sDatLen; i++ ) {                       // Read menu string
      rcvByte = Serial3.read(); 
      sDat[i] = rcvByte;                                     // fill array with received bytes
      delay(1);                                              // delay needed because incoming data @ 1byte/ms
    }
    return true;                                              // flags were found and data read
  }
  else
    return false;                                             // No valid serial data received
}
/*-------------------------------------------
 byte get_input(){
 while (Serial3.available()){
 data_in[index] = Serial3.read();
 index++;
 }
 }
 */
//------------------------------------------
void setup(){
  Serial.begin(9600);
  Serial3.begin(9600);
}
//-----------------------------------------
void loop(){// let labview send string, wait about 5 seconds to send hex string
  //  get_input();
  readMenu(byte *sDat, int data_in_length);
   /*for (int j = 17; j < 19; j++){
   Serial.println(data_in[17], HEX);// should be 4F4B = "OK"
   if(data_in[17] == 79){
   Serial.println("O");
   }
   Serial.println(data_in[18], HEX);
   if(data_in[18] == 75){
   Serial.println("K");
   }
   //}
   }
   }*/
}












