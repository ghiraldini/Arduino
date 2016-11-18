

bool waitForSerial1data() {

  unsigned long beginWait = millis();                            // record current millis for start of wait
  unsigned long elapsed = 0;                                     // elapsed time
   
  while(!Serial1.available()) {                                  // loop until there is data to be read or timeout
    delay(10);                                                   // A short delay to allow for forced breaks
    elapsed = millis() - beginWait;                              // calculate timeout
    if(elapsed > maxWait)                                        // exit if no serial data has arrived
      return false;                                              // no serial data has arrived
  }
  return true;                                                    // data has been detected in serial port 1
} 


bool readSwcaPing(byte *sDat, int sDatLen) {                  // General serial read routine for SWCA port

  byte rcvByte = 0x0;                                         // var to hold each byte value from serial buffer 
  wipeS1data();                                               // clear array to hold received data from serial buffer

  if(waitForSerial1data()) {                                  // hangout till serial data arrives
    timeout( START );                                         // data has arrived so start safety timer to prevent buffer underrun
    do {                                                      // Look for first flag  ( SWCA response to 0x01 seems to only have a single flag )
       if( timeout(CHECK) ) {
         timeout( STOP );
         return false;
       }
       rcvByte = Serial1.read();
    } while(rcvByte != 0x80);                                 // Read bytes until first flag (0x80) is found

    for(int i = 0; i < sDatLen; i++ ) {                       // Read bytes from serial port 1 
     rcvByte = Serial1.read(); 
     sDat[i] = rcvByte;                                       // fill array with received bytes
     delay(2);                                                // delay needed because incoming data @ 1byte/ms
    }
    if( debug ) {
    Serial.println("SWCAping read response SUCCESS");
    }
    return true;                                              // flags were found and data read
  } else {
    if( debug ) {
    Serial.println("SWCAping read response FAILED");
    }
    return false;                                             // No serial data to validate
    }
}

