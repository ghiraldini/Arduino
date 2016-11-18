// Program: SWCA_Field_Test_V7b.pde
// Date: 5/17/2010
// Authors: Bill Collins, Jason Ghiraldini

// Test platform to simulate communication with Xantrex SWCA adapter
// This code is designed to run on an Arduino MEGA acting as the
// remote wireless monitoring unit connected to a Xantrex SWCA 
// communications adapter through serial port 1.
// The data passed through Serial1 should be sent via an XBee radio 
// configured in non-API pass-through mode to simulate the serial connection with the
// SWCA.
// This program expects that another Arduino will receive the serial data and respond 
// with a string designed to emulate the response of the SWCA adapter. 

// ----------------------------------------------------------------------------------------------------------------------- Required Libraries

  #include "XBee.h"                                                          // Library for Xbee Communication
  #include "Wire.h"                                                          // Library for Real Time Clock
  #include <EEPROM.h>                                                        // Library to allow writing variables to EEPROM
  #define DS1307_I2C_ADDRESS 0x68                                            // This is the I2C address of Real Time Clock  

// ----------------------------------------------------------------------------------------------------------------------- Operational Tweaks

// *** Change these parameters to modify behavior of system ***
  const unsigned long POLLMINUTES = 5;                                       // set interval for reading inverter data in minutes

  const int s1len = 40;                                                      // size of temp array to hold bytes from swca
  unsigned long maxWait = 30000;                                             // milliseconds to wait for data from serial port 1 
  unsigned long minWait = 15000;                                             // milliseconds for smaller wait for serial 1 data 
  unsigned long xbWait =  20000;                                             // milliseconds to wait for ping response from LabVIEW  
  int BETWEENMENUS = 50;                                                     // milliseconds to pause between successive menu item requests to SWCA
  int max_file_number = 15;                                                 // when fileNumber = max_file_number go to delete_files
  unsigned long resetWindow = 10000;                                         // milliseconds to wait on startup for button press 
  unsigned long resetHoldPeriod = 3000;                                      // milliseconds button must be held to initiate file system renumbering and delete
  int menuRetryLimit = 3;                                                    // number of times to auto retry a menu read
  int SWCApingRetryLimit = 3;
  
// ----------------------------------------------------------------------------------------------------------------------- Debug variables
// ***  comment these out for final release
  int debugTally;            // *** debug code - var to hold calculated hash of recevied menu string
  uint16_t *debugHash;       // *** debug code - pointer to hash codes  
// *** set these to false for final release  
  bool debug = true;                                                         // turn on debug output to serial console
  bool includeLabVIEW = true;                                                // turn off/on ping and send for testing
  bool includeOil = false;                                                   // turn off/on oil sensor logic 
// ----------------------------------------------------------------------------------------------------------------------- Digital I/O pin assignments 

  int systemMaintPin = 30;                                                   // digital pin for system maintenance mode switch (inverted logic active = closed = low )
  int maintLedPin =    32;                                                   // digital pin for maintenance status LED
  int oilPowerPin =    22;                                                   // digital pin to supply +5V to oil circuit
  int oilSensorPin =   24;                                                   // digital pin for oil level sensor  
  int oilMaintPin =    26;                                                   // digital pin for oil maintenance switch
  int oilAlertLedPin =  4;                                                   // digital pin for oil alert LED
  int oilMaintLedPin =  5;                                                   // digital pin for oil maintenance LED
  int fileResetPin =    7;                                                   // digital pin for resetting file system vars and delete all files from stick

// ----------------------------------------------------------------------------------------------------------------------- XBee radio vars

  XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x403A34AD);       // 64 bit address of Project Base 900MHz Radio   
//  XBeeAddress64 destination = XBeeAddress64(0x0013A200, 0x403A34AC);       // 64 bit address of Jason's Project Base 900MHz Radio 
//  XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x40547AFE);     // 64 bit address of Bill's Base 900MHz Radio  
//  XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x403A349E);     // 64 bit address of Bill's Base 900MHz Radio  
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();                        // transmit response packet
  ZBRxResponse rx = ZBRxResponse();                                          // declare response for Digimesh packet type   
  XBee xbee = XBee();                                                        // Declare an instance of the XBee class     
  uint8_t TX_payload[33];                                                    // results from polling inverter  
  
// ----------------------------------------------------------------------------------------------------------------------- Jason's vars
  bool catch_up_ping_fail;
  bool still_need_to_catch_up;
  bool ping_result;
  bool del_complete = false;
  int low_limit = 10;
//  int ping_result;                                                           // status from labview ping
  int file_num;                                                              // initalize file numbering for USB stick
  int last_file;                                                             // file number of last successful transmission
  bool in_catch_up_mode;                                                      // flag to show in catch_up, i.e files saved but not transmitted to base
//  int vdip_rts = 34;                                                         // CTS (pin 10) of VDIP
  int vdip_rts = 52;
  int time_date[5];                                                          // array to save time and date
  byte file_data[70];                                                            // variable to read serial
  uint8_t f_data[33];                                                        // array to save data from file

// ----------------------------------------------------------------------------------------------------------------------- General Constants and Variables

  const byte MENULEFT =  0x4C;                                               // ascii (76d) = 'L'
  const byte MENURIGHT = 0x52;                                               // acsii (82d) = 'R'
  const byte MENUUP =    0x55;                                               // ascii (85d) = 'U'
  const byte MENUDOWN =  0x44;                                               // ascii (68d) = 'D'
  const int START = 1;                                                       // used as a flag for timeout function
  const int CHECK = 2;                                                       // used as a flag for timeout function
  const int STOP = 3;                                                        // used as a flag for timeout function
  unsigned long elapsedTime;                                                 // used by timeout function
  unsigned long startTime;                                                   // used by timeout function
  bool systemMaintMode = false;                                              // system status status 
  bool previousSystemMode = false;  
  bool oilMaintMode;                                                         // oil maintenance mode status, closed = active = true = high
  bool previousOilMaintMode = false;  
  bool oilSensor;                                                            // oil sensor status, closed = low oil = true = high
  bool previousOilSensorMode = false;
  byte modeBits;                                                             // byte for alert message byte 2, each bit is an alert status - see documentation for communication protocol
  
// ----------------------------------------------------------------------------------------------------------------------- Menu validation hash codes

// The following validation strings are hash values based on the sum of the first
// 14 ascii characters received after the flag sequence 0x80 0xE0 is received in response to a menu navigation command.
// The hash sum is found as the lowest two bytes of the HEX sum
// note: sizeof() will not return the literal number of bytes in the array because the hex values are two bytes each.

  uint16_t hashGenTop[] =   { 0x54C };                                                          // Generator Menu 2.0
  uint16_t hashHome[] =     { 0x513 };                                                          // Generator Menu 2.1 
  uint16_t hashMeterTop[] = { 0x880 };                                                          // Meter Menu 4.0
  uint16_t hashErrorTop[] = { 0x4CE };                                                          // Error Menu 5.0
  uint16_t hashGen[] =      { 0x543, 0x581, 0x584, 0x4F2, 0x4EC, 0x520, 0x566};                 // Generator Menu 2.2 - 2.8
  uint16_t hashMeters[] =   { 0x583, 0x330, 0x2C0, 0x575, 0x543, 0x40F, 0x32C, 0x4A5, 0x54E };  // Meters Menu 2.1 - 2.9
  uint16_t hashErrors[] =   { 0x4DF, 0x4F3, 0x3F7, 0x4BB, 0x48D, 0x574 };                       // Errors Menu 2.1 - 2.6

// ----------------------------------------------------------------------------------------------------------------------- General variables and flags

  byte swcaInit[] =         { 0x01, 0x47, 0x4C };                            // SWCA initialization string ( 0x47 = 'G', 0x4C = 'L' which takes us to the top level menu of whatever group was preveiously selected)
  byte s1Data[s1len];                                                        // container for incoming serial port 1 data                                                     
  byte extractedData[] =    { 0x20, 0x20, 0x20, 0x20 };                      // container for extracted menu data to be inserted into TX_payload                                             
  unsigned long pollInterval;                                                // The calculated polling interval in milliseconds
  unsigned long elapsed = 0;                                                 // timer for polling cycle
  unsigned long checkelapsed = 0;                                            // calculated elapsed time var
  unsigned long pollStart = 0;                                               // begin time in millis for calculating polling interval
  bool startcycle = true;                                                    // flag to manage polling interval
  byte ledStatus = 0x00;                                                     // byte to hold led status bits from inverter
  bool initFileSystem;                                                       // used to set/reset file number system and preserve or delete files on USB stick



// ----------------------------------------------------------------------------------------------------------------------- Program loops
void setup() {
  
    Serial.begin(9600);                                                      // Initialize serial port 0 for troubleshootong
    Serial1.begin(9600);                                                     // Port 1 for SWCA adapter
    Serial2.begin(9600);                                                     // Port 2 for VDIP USB storage
    Serial3.begin(9600);                                                     // Port 3 for XBee radio  
    Wire.begin();
    
    pollInterval = POLLMINUTES*60*1000;                                      // Calculate polling interval in milliseconds
    pollStart = millis();                                                    // log starting time for polling interval

    pinMode(systemMaintPin, OUTPUT);                                         // initialize port for pullup mode
    digitalWrite(systemMaintPin, HIGH);                                      // enable 20K pullup resistor
    pinMode(systemMaintPin, INPUT);                                          // once pullup is enabled redefine port to read switch state
    pinMode(maintLedPin, OUTPUT);                                            // set pin for simple output (no pullup)
    
    pinMode(fileResetPin, OUTPUT);                                           // configure FIle Reset pin for internal pullup
    digitalWrite(fileResetPin, HIGH);                                        
    pinMode(fileResetPin, INPUT);                                            // now set it back to normal (pullup remains active) 
    
    pinMode(oilPowerPin, OUTPUT);                                            // provide 5V to oil sensor circuit
    pinMode(oilSensorPin, INPUT);                                            // 
    pinMode(oilMaintPin, INPUT);                                             //
    pinMode(oilMaintLedPin, OUTPUT);                                         //
    pinMode(oilAlertLedPin, OUTPUT);                                         //
            
    pinMode(vdip_rts, OUTPUT);                                               // set the CTS of VDIP as output
    
    Serial2.print("IPA");                                                    // sets the vdip to use ascii numbers 
    Serial2.print(13, BYTE);                                                 // return character to tell vdip its end of message

    initializeFileSystem();                                                  // reads File Reset button and initializes file numbering and/or deletes files on stick

}

void loop() {
  uint8_t TX_payload[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x44, 0x7, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0xA0};
/*
    checkMaintMode();
  
    while( startcycle ) {                                                    // Polling cycle of inverter menu reads - Set POLLMINUTES to control interval  
      wipeTXpayload();                                                       // reset payload string before reconstructing during this cycle
      pingSWCA();                                                            // Make sure we are connected to SWCA and have control
//      getLedStatus(ledStatus);                                             // Read SWCA leds
      getGenData();                                                          // Read SWCA generator menu data
      delay(1000);                                                           // delay needed to allow inverter to transition to new menu
      getMeterData();                                                        // Read SWCA meter menu data
      delay(1000);
      getErrorData();                                                        // Read SWCA error menu data 
      get_date();                                                            // Get time stamp from Real Time Clock 
      
      TX_payload[0] = 0x01;                                                  // Set message type to 'DATA' 
      TX_payload[32] = 0xA0;                                                 // Add message termination character
      insertDateTX();                                                        // Insert time stamp into transmission string
*/    Serial.println();
      Serial.println();
      Serial.print("File Number to write to stick: ");
      Serial.println(file_num);
      write_file(file_num, TX_payload, sizeof(TX_payload));                  // Save extracted polling data to USB thumb drive
 
      if(includeLabVIEW) {                                                   // set boolean value above to turn on/off testing of ping and send to base
          if( ping_labview(sizeof(TX_payload)) ) {                           // make sure LabVIEW is online and responding
          Serial.println("Return from Ping");
              if(del_complete){
                write_file(file_num, TX_payload, sizeof(TX_payload));
              }
              Serial.print("Ping Result: ");
              Serial.println(ping_result);
              Serial.print("In catch up mode: ");
              Serial.println(in_catch_up_mode);
              Serial.print("Still need to catch up: ");
              Serial.println(still_need_to_catch_up);
              
              if(ping_result && still_need_to_catch_up){
                catch_up(file_num, sizeof(TX_payload), last_file);
              }
              if(ping_result && !still_need_to_catch_up){
              Serial.println("Sending to Xbee function.");
              send_xbee(TX_payload, sizeof(TX_payload), file_num, last_file);// Send extracted polling data to Base Station
              }
          } 
      }

      checkFileLimit();                                                      // make sure that file count has not exceeded capacity
/*      startcycle = false;                                                    // reset polling interval flag to disable read cycle until polling timeout
      
      if(debug) {                                                            // display transmission payload message on serial debug console
         Serial.print( "TX string = ");                                      // *** debug code
         writeTX(TX_payload, sizeof( TX_payload ));                          // *** debug
         Serial.println();                                                   // *** debug code   
         Serial.println("Polling Cycle Complete");                           // *** debug code          
      }  
  } // end of polling loop
    
      elapsed = millis();                                                    // check elapsed time to control polling interval  
     checkelapsed = elapsed - pollStart;                                     // calculated elapsed cycle time
     if( checkelapsed > pollInterval ) {                                     // check to see if time to poll SWCA
       startcycle = true;                                                    // reset flag to enable next polling cycle
       pollStart = millis();                                                 // reset start counter for next polling cycle
     }

     delay(500);            
*/}

//------------------------------------------------------------------------------------------------------------------- Function definitions

// A maintenance utility function run at startup. If File Reset button on module held for 3 seconds out of 10 during boot load
// the file numbering system will be reset and all files on USB stick deleted. If no action is taken the file numbering 
// scheme will be read from EEPROM and continue from last file sequence. 
void initializeFileSystem() {

  unsigned long windowElapsed;            //
  unsigned long windowStart;              //
  unsigned long resetStart;               //
  unsigned long resetHeld;                //
  
  if(debug) {
    Serial.println(" Starting up: press FILE RESET for 3 seconds within the next 10 seconds to reset file system"); 
    Serial.println(" Or wait for 10 seconds to preserve previous number sequence");
  }
  
  windowStart = millis();
  do {
    int testPin = digitalRead(fileResetPin);
    if(testPin == LOW) {                                        // check to see if reset button is pressed, using inverse logic due to pullup config
       resetStart = millis();
       resetHeld = resetStart;
       while( resetHeld - resetStart  < resetHoldPeriod) {      // wait for minimum time 
         resetHeld = millis();
         delay(5);
       }
       testPin = digitalRead(fileResetPin);
       if(testPin == LOW) {                                     // check to see if reset button is still pressed
          file_num = EEPROM.read(1);                            // read last file number pointer from EEPROM to send to delete function
          delete_files(file_num);                               // delete all files up to and including file number pointer on USB stick
          
          EEPROM.write( 1,1 );
          file_num = 1;
          initFileSystem = true;
          EEPROM.write( 2,0);
          last_file = 0;
          if(debug) {
            Serial.println("Resetting file system");
            Serial.print("file_num = ");
            Serial.print(EEPROM.read(1), DEC );
            Serial.print(" last_file = ");
            Serial.println(EEPROM.read(2), DEC);
          }
       } 
    } 
    windowElapsed = millis();   
  } while( windowElapsed - windowStart < resetWindow );
   if( !initFileSystem ) {
         file_num = EEPROM.read(1);                             // Get stored values for file system naming
         last_file = EEPROM.read(2);
         initFileSystem = false;
         if(debug) {
            Serial.println("Reading file system parameters from EEPROM");
            Serial.print("file_num = ");
            Serial.print(file_num);
            Serial.print(" last_file = ");
            Serial.println(last_file);
         }
   }
}

void checkMaintMode() {

  // check System Maintenance Switch
   systemMaintMode = !digitalRead(systemMaintPin);          // read switch state (inverted logic, ie low = true )
   
   if( systemMaintMode != previousSystemMode ) {
       
       if(!digitalRead(systemMaintPin)) {                    // Check to see if maintenance switch is enabled
          digitalWrite(maintLedPin, HIGH);
          systemMaintMode = true;
          if(debug) {                                       // *** debug code  
            Serial.println("Maintenance Mode Active");
          } 
         if( includeLabVIEW) {     
           sendAlert();                                    // send alert to Base Station
         } 
          while(!digitalRead(systemMaintPin)) {             // loop until maintenance mode switch is toggled, no polling will occur while in Maintenance Mode
            delay(100);
          } 
          digitalWrite(maintLedPin, LOW);        
          systemMaintMode = false;    
          if(debug) {                                       // *** debug code  
            Serial.println("Maintenance Mode Disabled");
          } 
         if( includeLabVIEW) { 
            sendAlert();                                      // clear alert with Base Station
         }
       }
       previousSystemMode = systemMaintMode;
   } // end of system maintenance mode check 
      
// Check Oil Sensor Maintenance Mode
  if(includeOil) {
     
     digitalWrite(oilPowerPin, HIGH);          // prepare for read by bringing pin high to enable reading of sensors
     delay(100);                               // wait for pin to settle 
  
     oilMaintMode = digitalRead(oilMaintPin);      // read current state of switch
     if( oilMaintMode != previousOilMaintMode ) {  // if state has changed from previous value update status

 
         if(digitalRead( oilMaintPin ) ) {                    // 
              oilMaintMode = true;
              digitalWrite( oilMaintLedPin, HIGH );
              if( includeLabVIEW ) {
                 sendAlert();
              }
            if(debug) {
              Serial.println("Oil Maintenance Mode Active");
            }
         } else if( digitalRead(oilSensorPin)) {
              digitalWrite(oilAlertLedPin, HIGH);
              if(debug) {
                  Serial.println("Oil level low");
              }
              oilSensor = true;
              if( includeLabVIEW ) {
                 sendAlert();
              }
         } else {
              oilSensor = false;
              digitalWrite(oilAlertLedPin, LOW);
              if(debug) {
                  Serial.println("Oil level normal");
              }
              if( includeLabVIEW ) {
                 sendAlert();
              }
           }
   
         if(digitalRead( !oilMaintPin )) {
            digitalWrite( oilMaintLedPin, LOW );
            oilMaintMode = false;
            if(debug) {
              Serial.println("Oil system operational");
            }
            if( includeLabVIEW ) {
               sendAlert();                          // Clear oil maintmode alert 
            }
         }
         digitalWrite( oilPowerPin, LOW );          // remove power until next read cycle 
     }
    previousOilMaintMode = oilMaintMode;   
  } // end of if( include oil
}

// A time limited loop that waits up to maxWait milliseconds for data to arrive in serial 1 buffer
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

// A time limited loop that waits up to maxWait milliseconds for data to arrive in serial 1 buffer
bool waitForSerial3data() {

  unsigned long beginWait = millis();                            // record current millis for start of wait
  unsigned long elapsed = 0;                                     // elapsed time
   
  while(!Serial3.available()) {                                  // loop until there is data to be read or timeout
    delay(10);                                                   // A short delay to allow for forced breaks
    elapsed = millis() - beginWait;                              // calculate timeout
    if(elapsed > xbWait)                                         // exit if no serial data has arrived
      return false;                                              // no serial data has arrived
  }
  return true;                                                   // data has been detected in serial port 1
} 

// Make sure the inverter adapter is functioning and communicating with the Arduino, also used to wake SWCA from sleep
bool pingSWCA() {
  int pingAttempt = 0;                                                // counter for auto retry
  bool SWCApingSUCCESS = false;                                       //  
  
  while( !SWCApingSUCCESS && pingAttempt < SWCApingRetryLimit ) {     // SWCApingRetryLimit var defined in operational global var section at top 
     Serial1.flush();
     sendSwcaPing( swcaInit, sizeof(swcaInit) );                      // send initialization string to SWCA
     readSwcaPing(s1Data, sizeof(s1Data));                            // peek at return string
     if(debug) {
       Serial.print("SWCA ping response = ");
       writeHexArray( 0, s1Data, sizeof(s1Data));                     // *** debug show response on console
       Serial.println();
     }
     if( validateMenu(hashGenTop, 0, s1Data, sizeof(s1Data) ) ){
       SWCApingSUCCESS = true;  
     } else {
       SWCApingSUCCESS = false;
     }
     pingAttempt++;

  }
  
  return SWCApingSUCCESS;
}

// Send ping string to SWCA via Serial1 - this will ensure that the SWCA is awake and in control of the menu selection
void sendSwcaPing( byte *array, int arrayLen ) {
        while (arrayLen--) 
          Serial1.write(*array++);                               // 
}

// Read each menu item as received at the serial buffer
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

// Read LabVIEW ping response received at the serial buffer
bool readLabVIEWPing(byte *sDat, int sDatLen) {               // General serial read routine for SWCA port

  byte rcvByte = 0x0;                                         // var to hold each byte value from serial buffer 

  if(waitForSerial3data()) {                                  // hangout till serial data arrives
    timeout( START );                                         // data has arrived so start safety timer to prevent buffer underrun infinite loop
       if(debug) {
         Serial.print("\tPing response: ");  // *** debug 
       } 
    do {                                                      // Look for ***
       if( timeout(CHECK) ) {
         timeout( STOP );
         return false;
       }
       rcvByte = Serial3.read();
       if(debug) { 
         Serial.print(rcvByte, HEX);       // *** debug
       }  
    } while(rcvByte != 0x7E);                                 // Read bytes until start delimiter (0x7E) is found

    for(int i = 0; i < sDatLen; i++ ) {                       // Read bytes from serial port 3 // sDatLen+2 for display
       rcvByte = Serial3.read(); 
       if(debug) {
         Serial.print(rcvByte, HEX);
         Serial.print(" ");
       }
       sDat[i] = rcvByte;                                       // fill array with received bytes
       delay(10);                                                // delay needed because ***
    }
    if(debug) {                                         // *** debug code
      Serial.println();
      Serial.println("\tLabVIEW ping received ");        // *** debug
      Serial.println();
    }
    return true;                                              // flags were found and data read
  }
  if(debug) {
  Serial.println("\tERROR - Timed out waiting for LabVIEW  ");        // *** debug
  }
  return false;                                               // No serial data to validate
}

// Sets inverter menu to Generator menu 2.1 - absolute navigation command
bool goGen21() {                                               // navigation to home (Gen2.1) w/validation
//  bool genStatus = false;  
  Serial1.flush();
  Serial1.write('G');                                          // 'G' goes directly to Generator menu 2.1, be careful since multiple 'G' commands in a row cause the gen menu 2.1 items to be selected sequentially which could alter inverter functionality                  
  if(readMenu(s1Data, sizeof(s1Data))) {  
      if(debug) {
        Serial.println("Gen 21 OK");
      }    
     if( validateMenu(hashHome, 0, s1Data, sizeof(s1Data) ) ) {
       if(debug) {
         Serial.println("Generator read and validation OK");
       }
     return true;
     } else {
            if(debug) {
                Serial.println("Gen 21 validation failed");
            }
            return false;                                      // validation failed 
       } 
  } else {
           if(debug) {
              Serial.println("Gen 21 read failed");
           }
          return false;
  }
}  
            

// Read each menu item as received at the serial 1 buffer
bool readMenu(byte *sDat, int sDatLen) {                      // General serial read routine for SWCA port

  byte rcvByte = 0x0;                                         // var to hold each byte value from serial buffer 
  wipeS1data();                                               // clear array to hold received data from serial buffer

  if(waitForSerial1data()) {                                  // hangout till serial data arrives
    timeout(START);
    do {                                                      // Look for first flag  
       if(timeout(CHECK)) {                                   // prevent endless loop if no data arrives
 //        timeout(STOP);
          if(debug) {
             Serial.println("Timeout looking for first menu flag");            // *** debug
          }
         return false;
       }
       rcvByte = Serial1.read();
    } while(rcvByte != 0x80);                                 // Read bytes until first flag (0x80) is found

    timeout(START); 
    do {                                                      // keep reading bytes until 2nd flag (0xE0) found
       if(timeout(CHECK)) {                                   // prevent endless loop if no serial data arrives
//         timeout(STOP);
          if(debug) {
             Serial.println("Timeout looking for second menu flag");            // *** debug
          }
         return false;                                        // second flag not found
       }
      rcvByte = Serial1.read();     
    } while(rcvByte != 0xE0); 
   
    for(int i = 0; i < sDatLen; i++ ) {                       // Read menu string
       rcvByte = Serial1.read(); 
       if( ( rcvByte > 0x1F && rcvByte < 0x7F ) || ( rcvByte > 0xBF && rcvByte < 0xD0 ) ) {
         sDat[i] = rcvByte;                                   // fill array with received bytes
       } else if( i < 32 ) {                                  // If the received byte is not a valid byte throw it away and decrement the counter
         --i;
       }
       delay(1);                                              // delay needed because incoming data @ 1byte/ms
    }
    return true;                                              // flags were found and data read
  }
  else
    return false;                                             // No valid serial data received
}

// Helper function to print an array to a serial port
void writeHexArray(int port, byte *array, int arrayLen) {      

  switch (port) {
    case 0:                                                  // Used to print mix of ascii chars and hex values to serial console
      for( int i = 0; i < arrayLen; i++) {
        if( array[i] > 0x1F && array[i] < 0x7F ) {            // if printable alpha/numeric ascii code
          Serial.print(array[i]);                             // print character instead of hex value
        } else {
          Serial.print(array[i], HEX);                        //  otherwise print the raw hex value
          Serial.print(" ");
        }
      }

      Serial.println();                                        // print a new line to prepare for next string display
      break;
      
    case 1:    
      while (arrayLen--) 
        Serial1.write(*array++);                               // write each byte value in array to serial port 1
      break;
    case 2:    
      while (arrayLen--)
        Serial2.write(*array++);                               // write each byte value in array to serial port 2
      break;
    case 3:    
      while (arrayLen--)
        Serial3.write(*array++);                               // write each byte value in array to serial port 3
      break;
    default: 
      break; 
  }
  return;
}

void writeTX( byte *array, int arrayLen) {
  while(arrayLen--) {
    Serial.print(*array++, HEX);
    Serial.print(" ");
  }
  Serial.println();
}
 
void wipeS1data() {                                            // Zero out array for incoming serial data
  for(int i = 0; i < 40; i++)
    s1Data[i] = 0x20;                                          // fill array with spaces so that the printout is a little more readable
}  



void getGenData() {                                            // Read Gen2.2 - Gen2.9 data

//  bool goodtogo = false;  
  
//  goodtogo = goGen21();                                        // Goto home and validate
//  if(debug) {
//  Serial.print("HOME status = ");
//  Serial.println(goodtogo);
//  }
  int readAttempt = 0;
  bool validData = false;
  bool readSuccess = false;
  
  
 while( !readSuccess && !validData && readAttempt < menuRetryLimit ) { 
  if( goGen21()) {                                           
      for( int i = 0; i < 7; i++ ) {                           // Read each of 7 Generator menus 
          Serial1.flush();  
          Serial1.write(MENUDOWN);                                 // Send 0x44, ascii 'D' to SWCA
           
          if( readMenu( s1Data, sizeof(s1Data) ) ) {
            if( validateMenu( hashGen, i, s1Data, sizeof(s1Data) ) ) {
               extractData( extractedData, s1Data, sizeof(s1Data) ); 
               stuffTXbits( cnvtData2bool( extractedData ), i, 6, 29 );
            } else {
                     validData = false;                              // validation failed
                     if(debug) {
                       Serial.print("Validation of Generator menu 2.");
                       Serial.print(i+2);
                       Serial.println(" failed");
                     }
                     break;                                          // exit this iteration of for loop
                   }
            debugWrite(i);                      // *** debug       
            validData = true;                                 // validation passed  
          } else {
                    readSuccess = false;                             // read failed 
                    if(debug) {
                       Serial.print("Read of Generator menu 2.");
                       Serial.print(i+2);
                       Serial.println(" failed");
                     }
                    break;                                           // exit this iteration of for loop
                 }
          readSuccess = true;                                 // read OK
          delay(BETWEENMENUS);                                    // insert short delay 
      } // end of for( read menu item loop... 
        if( validData && readSuccess ) {            // if read or validation success we don't need to retry
            readAttempt = menuRetryLimit;              // so set attempt  >= to limit so outer loop does not execute        
        } else {
                 readAttempt++;
                }
 //     debugWrite(i);                                                // *** debug
      }  // end if if( goGen21...
   }
}

void getMeterData() {                                              // send navigation cmds and read results for Meter menu
  bool goodtogo = false;  
  
  goodtogo = goGen21();                                            // Goto home and validate
  if( goodtogo) { 
      Serial1.write(MENURIGHT);                                    // From Gen2.1, 0x52, ascii 'R' goes to top of 3.0
      delay(500);                                                  // minimum delay needed to go between top level menus - horizontally
      Serial1.write(MENURIGHT);                                    // From top of 3.0 'R' goes to top of 4.0 - Meters 
      delay(500);
      Serial1.flush();                                                                         
      Serial1.write(MENUDOWN);                                     // 0x44, 'D' takes us to Meters2.1
      
      for( int i = 0; i < 9; i++ ) {                               // Read each of 9 Meter menus  
        readMenu( s1Data, sizeof(s1Data) );
        validateMenu( hashMeters, i, s1Data, sizeof(s1Data));  
        extractData( extractedData, s1Data, sizeof(s1Data) ); 
        stuffTXbytes( TX_payload, i );
        delay(BETWEENMENUS); 
        debugWrite(i);                                              // *** debug code
        if( i < 8 ) {
          Serial1.write(MENUDOWN);                                       // Send 'D' to SWCA to advance to next menu         
        }
      } 
   }
}


void getErrorData() {                                              // send navigation cmds and read results for Error menu
  bool goodtogo = false;  
  
  goodtogo = goGen21();                                            // Goto home and validate
  if( goodtogo) { 
      Serial1.write(MENURIGHT);                                    // From Gen2.1, 'R' goes to top of 3.0
      delay(800);
      Serial1.write(MENURIGHT);                                    // From top of 3.0 'R' goes to top of 4.0 - Meters
      delay(800); 
      Serial1.write(MENURIGHT);                                    // 'R' takes us to Error 5.0
      delay(800);
      
      for( int i = 0; i < 6; i++ ) {                               // Read each of 6 Error menus  
        Serial1.flush();                                           // Don't care about intermediate return strings
        Serial1.write(MENUDOWN);                                       // Send 'D' to SWCA to advance to next menu         
        readMenu( s1Data, sizeof(s1Data) );
        validateMenu( hashErrors, i, s1Data, sizeof(s1Data));  
        extractData( extractedData, s1Data, sizeof(s1Data) ); 
        stuffTXbits( cnvtData2bool( extractedData ), i, 5, 30 );
        delay(BETWEENMENUS);
        debugWrite(i);                                              // *** debug code
      }
   }
   Serial1.write(MENULEFT);                                        // Position menu to top 
}

void getLedStatus(byte ledstat) {

    Serial1.flush();
    Serial1.write(0xE3);                                      // send command to SWCA to read LEDs

  
}

bool validateMenu(uint16_t *hash, int hashPosition, byte *datIn, int datLen ) {   // compare received menu against hash
  uint16_t tally = 0x0;                                     
  for( int i = 0; i < 14; i++ ) {
    tally = tally + datIn[i];                                      // Sum first 14 bytes of menu
  }
  debugTally = tally;                        // *** debug code
  debugHash = hash;                          // *** debug code 
  
  if( tally == hash[hashPosition] ) {
    return true;
  } else
      return false;  
}

void extractData(byte *eDat, byte *datIn, int datLen ) {           // search menu string and extract data bytes
  clearExtractData();
  for( int i = 0; i < datLen; i++ ) {
    if( datIn[i] == 0xCD || datIn[i] == 0xCB ) {
      eDat[0] = datIn[i+1];
      eDat[1] = datIn[i+2];
      eDat[2] = datIn[i+3];
      eDat[3] = 0x20;
    } else if( datIn[i] == 0xCC ) {
      eDat[0] = datIn[i+1];
      eDat[1] = datIn[i+2];
      eDat[2] = datIn[i+3];
      eDat[3] = datIn[i+4];
    }
  }
}

void debugWrite(int hashPosition ) {                              // *** Debug helper function 

  writeHexArray( 0, s1Data, sizeof(s1Data));                     // write serial menu string received                
  Serial.print(" "); 
  Serial.print("Tally vs hash: ");  
  Serial.print( debugTally );       
  Serial.print(" ");              
  Serial.print(debugHash[hashPosition]); 
  Serial.print(" Extracted: ");                                  // write extracted data point
  writeHexArray( 0, extractedData, sizeof(extractedData));   
  Serial.println();
//  Serial.print("Payload: ");
//  Serial.print( "byte 29 = " );
//  Serial.println( TX_payload[29], BIN);
//  Serial.print("byte 30 = ");
//  Serial.println( TX_payload[30], BIN);
}
 
void clearExtractData() {                                      // helper function to clear extractedData[]
  for( int i = 0; i < 4; i++ ) {
    extractedData[i] = 0x20;
  }
}

bool cnvtData2bool( byte *eDat ) {                            // helper function to convert ascii extractedData[] to boolean 
  
  if( eDat[1] == 0x4E ) {
    return false;                      
  } else return true;
}

void stuffTXbits( bool boolDat, int cntr, int msbpos, int payloadpos ) {
  if( boolDat )
    bitSet(TX_payload[payloadpos], msbpos-cntr);
  else bitClear(TX_payload[payloadpos], msbpos-cntr);
}  

void wipeTXpayload() {
  for( int i = 0; i < sizeof( TX_payload); i++ ) {
    TX_payload[i] = 0xFF;
  }
}

void stuffTXbytes( byte *payload, int menu ) {
  switch (menu) {
    case 0:                                                  // Meter menu 4.1
      payload[8] = extractedData[0];
      payload[9] = extractedData[1];
      payload[10] = extractedData[2];
      break;
    case 1:
      payload[11] = extractedData[0];                        // Meter menu 4.2
      payload[12] = extractedData[1];
      payload[13] = extractedData[2];
      break;
    case 2:
      payload[14] = extractedData[1];                        // Meter menu 4.3
      payload[15] = extractedData[2];
      break;
    case 3:
      payload[16] = extractedData[0];                        // Meter menu 4.4
      payload[17] = extractedData[1];
      payload[18] = extractedData[3];
      break;
    case 4:
      payload[19] = extractedData[0];                        // Meter menu 4.5
      payload[20] = extractedData[1];
      payload[21] = extractedData[3];
      break;
    case 5:
      payload[22] = extractedData[0];                        // Meter menu 4.6
      payload[23] = extractedData[1];
      payload[24] = extractedData[2];
      break;
    case 6:                                                  // Meter Menu 4.7 - No Grid Tie AC1, do not use 
      break;
    case 7:
      payload[25] = extractedData[0];                        // Meter menu 4.8
      payload[26] = extractedData[1];
      payload[27] = extractedData[2];
      break;
    case 8:
      payload[28] = extractedData[1];                        // Meter menu 4.9
      payload[29] = extractedData[2];
      break;
    default:
      break;
  }
}

// a simple function to check for timeout based on minWait
bool timeout( int c ) {
  
  if( c == START ) {
    startTime = millis();
    delay(1);
    return false;
  }
  
  if( c == CHECK ) {
    elapsedTime = millis() - startTime;
    if( elapsedTime > minWait ) {
      if(debug) {
      Serial.print("ERROR: Elapsed time waiting for data = " );
      Serial.println(elapsedTime);
      }
      return true;
    }
  } // else 
     // return false;
//  if( c == STOP ) {
//    elapsedTime = 0;
//  }
  return false;
}  

// Insert time and date info into Tx string for transmission
void insertDateTX( ) {
  TX_payload[1] = time_date[0];                // year
  TX_payload[2] = time_date[1];                // month    
  TX_payload[3] = time_date[2];                // day
  TX_payload[4] = time_date[3];                // hour
  TX_payload[5] = time_date[4];                // minute
}

// >> Bill's functions stop here << ------------------------------------------------------------------------

// Jason's functions start here << --------------------------------------------------------------------------
byte bcdToDec(byte val){
  return ( (val/16*10) + (val%16) );
}

unsigned long get_date(){            
  Wire.beginTransmission(DS1307_I2C_ADDRESS);   // transmit to the ds 1307
  Wire.send(0x00);                              // resets ds1307 to beginning of its registers
  Wire.endTransmission();                       // stop transmitting
  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);      // request 7 date and time bytes from slave ds1307, we'll read them all but discard the day_of_week
  int second = bcdToDec(Wire.receive() & 0x7f); // convert bytes to decimal format
  int minute = bcdToDec(Wire.receive());        
  int hour = bcdToDec(Wire.receive() & 0x3f);   
  int day_of_week=bcdToDec(Wire.receive());     
  int day = bcdToDec(Wire.receive());           
  int month = bcdToDec(Wire.receive());         
  int year = bcdToDec(Wire.receive());  
  time_date[0] = year+0x14;                          // save converted bytes to array sequence that matches our message type 1 protocol
  time_date[1] = month+0x14;                         // 0x14 or 20 decimal added to each value to avoid possible conflict with escape code characters 
  time_date[2] = day+0x14;                           // subtract 0x14 from each value to retreive the data and time
  time_date[3] = hour+0x14;
  time_date[4] = minute+0x14;
} 

void write_file(int file_num, uint8_t *payload, int packet_size){
del_complete = false;

if( debug) { 
 
  Serial.println( "Beginning write to local archive sequence" );
  Serial.print("File number = ");    //  *** debug
  Serial.print(file_num);
  Serial.print(", Last file = ");
  Serial.print(last_file);
  Serial.print(", Max file = ");      // *** mode debug
  Serial.print(max_file_number);
  Serial.print(", Packet size = ");
  Serial.println(packet_size);
 
}

  if (file_num == max_file_number){
    Serial.println("Over file limit, not writing to USB.");
    return;
  }
 
//  delay(500);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(file_num);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(500);
  Serial2.print("WRF ");          // write to file once it is open (number = bits to write)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  for(int i = 0; i < packet_size; i++) {
   Serial2.write(payload[i]);         // write data to file
     delay(50);
  }
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(file_num);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  
       if(debug) {
        Serial.println("Write to local archive cycle complete");
        Serial.println();
      }
} 

int read_file(int file_num2, int packet_size){
  Serial.print("Reading File: ");
  Serial.println(file_num2);
  int i = 0;                        // declare and initialize pointer for reading file
  byte rcvByte = 0x0;                  
  delay(500);
  Serial2.print("OPR ");            // open file for reading
  Serial2.print(file_num2);
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.flush();                  // clean out serial buffer
  Serial2.print("SEK ");            // set pointer of file to read
  Serial2.print(i);
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.print(13, BYTE);            
  Serial2.print("RDF ");           // Read from file xx (xx = number of bytes to read)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  delay(500);
  if(waitForSerial2data()) {                                  // hangout till serial data arrives
    timeout( START );                                         // data has arrived so start safety timer to prevent buffer underrun infinite loop
    do {                                                      // Look for ***
       if( timeout(CHECK) ) {
         timeout( STOP );
         return false;
       }
       rcvByte = Serial2.read();
    } while(rcvByte != 0x44);                                 // Read bytes until start delimiter (0x44) is found
    Serial.println("VDIP DATA SUCCESSFUL!!!!!");
    for(int i = 0; i < packet_size+10; i++ ) {                // Read bytes from serial port 2 
       rcvByte = Serial2.read(); 
       if(debug) {
         Serial.print(rcvByte, HEX);
         Serial.print(" ");
       }
       file_data[i] = rcvByte;                                 // fill array with received bytes
       delay(10);                                              // delay needed because ***
    }
  digitalWrite(vdip_rts, HIGH);   // set RTS high to prepare for closing file
  Serial2.print(13, BYTE);
  delay(2000);
  digitalWrite(vdip_rts, LOW);
  Serial.println();
  delay(2000);
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(file_num2);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
  int q = 9;
  for(int k = 0; k < packet_size; k++){// save desired data to global array
    f_data[k] = file_data[q];
    q++;
  }
}
Serial.print("F_DATA: ");
for (int a = 0; a < packet_size; a++){// print correct data of global array to verify
  Serial.print(f_data[a], HEX);
  Serial.print(" ");
}
Serial.println();
}

bool waitForSerial2data() {

  unsigned long beginWait = millis();                            // record current millis for start of wait
  unsigned long elapsed = 0;                                     // elapsed time
   
  while(!Serial2.available()) {                                  // loop until there is data to be read or timeout
    delay(10);                                                   // A short delay to allow for forced breaks
    elapsed = millis() - beginWait;                              // calculate timeout
    if(elapsed > xbWait)                                         // exit if no serial data has arrived
      return false;                                              // no serial data has arrived
  }
  return true;                                                   // data has been detected in serial port 2 / VDIP
} 

byte send_xbee(uint8_t *payload, int packet_size, int file_num1, int last_file1) {    

  ZBTxRequest zbTx = ZBTxRequest(destination, payload, packet_size);// message packet 
  
               if( debug ) {
                Serial.println("Sending data to LabVIEW");
              }  
  
  Serial.print("VDIP Data in XBEE send: ");
  for(int k = 0; k < packet_size; k++){
      Serial.print(f_data[k], HEX);
    }
    Serial.println();
  if(debug) {
    Serial.print("Sending: ");
    Serial.print(packet_size);
    Serial.print(" bytes, as: ");
    delay(100);
   for(int i = 0; i < packet_size; i++) {
     Serial.print( payload[i]);
   }
    Serial.println();
  }
//  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet 

  delay(1000);                     // small delay
  xbee.send(zbTx);                                                // after sending a tx request, we expect a status response
  xbee.readPacket(5000);                                          // wait up to 5 seconds for the status response
  if (xbee.getResponse().isAvailable()) {                         // look for response, 
    Serial.println("Response available");  
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){  // verify that response packet ID is type 0x8B 
      Serial.println("Response packet verified");
      xbee.getResponse().getZBTxStatusResponse(txStatus);         // if so, get embedded status bytes from frame
      if (txStatus.getDeliveryStatus() == SUCCESS){               // extract response status byte 9, if not SUCCESS (byte 9 = 0), assume not sent | if SUCCESS and previous not sent
        Serial.println("Delivery status SUCCESS"); 
        Serial.println("Data Sent");
        Serial.print("File Number: ");
        Serial.println(file_num);
        Serial.print("Last File Sent: ");
        Serial.println(last_file1);
        last_file = last_file1;
        if((last_file != file_num && in_catch_up_mode)
            || last_file != 0 || last_file == file_num)
        {
          if (in_catch_up_mode || last_file1+1 == file_num1){
            last_file1++;
            last_file = last_file1;
          }
           catch_up(file_num1, packet_size, last_file1);             // go to catch_up function to send previous files
        }
      } 
      else { // if not SUCCESS
        if(last_file1 == 0){                // no response and this is first failed transmission 
          last_file1 = file_num1;            // save file number that has not been sent to local variable
          EEPROM.write(2,last_file1);
          EEPROM.write(1,file_num1);
          last_file = last_file1;
          file_num = file_num1;
        }
      }
    }
  }
}

byte delete_files(int file_number1){
  if(last_file == 0){                           // only delete if all files have been sent
    for(int i = 1; i < file_number1+1; i++) {       // delete all files starting from fileNumber = 1
      Serial2.print("DLF ");
      Serial2.print(i);
      Serial2.print(".TXT");
      Serial2.print(13, BYTE);
      delay(50);
      Serial.print("Deleting File Number: ");
      Serial.println(i);
    }
    file_num = 1;
    EEPROM.write(1, 1);                          // save file number to EEPROM = 1    
    Serial.println("Done Deleting");
    del_complete = true; 
  }
 return del_complete;
}

int catch_up(int file_number, int packet_size, int last_file_update){    // send all failed transmission files
Serial.println("Catching Up...");
  if(last_file_update < file_number && last_file_update != 0){// send from first non sent file to present file
    in_catch_up_mode = true;                                              // set to 1, so send_xbee is not in infinite loop
    catch_up_ping_fail = false;
    read_file(last_file_update, packet_size);                   // read first non sent file
    delay(1000);
    Serial.print("VDIP Data in Catch up: ");
    for(int k = 0; k < packet_size; k++){
      Serial.print(f_data[k], HEX);
      Serial.print(" ");
    }
    Serial.println();
    if(ping_labview(packet_size)){
      Serial.print("Send last bad TX file number: ");
      Serial.println(last_file_update);
      last_file = last_file_update;
      EEPROM.write(1, file_number);
      EEPROM.write(2, last_file_update);
      send_xbee(f_data, sizeof(f_data), file_number, last_file_update);        // send file
    }
    still_need_to_catch_up = true;
  }
  else{
    Serial.println("Done Catching up");
    in_catch_up_mode = false;       // set back to zero after catch up is done
    still_need_to_catch_up = false;
    last_file_update = 0;                                               // set back to zero after catch up is done
    last_file = last_file_update;                                       // set global to zero
    file_num = file_number;
    EEPROM.write(1, file_num);
    EEPROM.write(2, last_file);
    Serial.print("File Number after catch up: ");
    Serial.println(file_number);
    Serial.print("Last File after catch up: ");
    Serial.println(last_file);
    if (file_num == max_file_number || file_num > low_limit)  {                // all files have been sent, check to see if over limit
      delete_files(file_number);                                           // if yes, delete all files while transmission is good
    }
  }
  still_need_to_catch_up = false;
}

//-----------------------------------------------------------------------------------------
int ping_labview(int packet_size) {
  uint8_t ping[] = {0x02, 0x3F, 0x3F, 0xA0 };                                       // payload - message type 2 for XBee API type 0x10 zbTx payload 
  uint8_t pingResponse[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                             0x00, 0x00, 0x00 };                                         // response string from zbResponse        
  
  ZBTxRequest zbTx = ZBTxRequest( destination, ping, sizeof(ping) );        // message packet for 900 MHz radios and 64bit address 
    
  if(debug) {
     Serial.println("\tPing LabVIEW");
   }
  
  xbee.send(zbTx);                                                          // after sending ping, we expect "OK" response
  xbee.readPacket(5000);                                                    // wait up to 5 seconds for the status response
  if (xbee.getResponse().isAvailable()){                                    // if there is a response, (there should always be one)
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){            // got a response, should be a 0x8B 
      xbee.getResponse().getZBTxStatusResponse(txStatus);                   // send transmission status response (series 1)
      if (txStatus.getDeliveryStatus() == SUCCESS){                         // get status from response
          if(debug) {
           Serial.println("\tGot TX status == SUCCESS from radio, now looking for ping response RX packet from LabVIEW");    // *** debug
          }
           readLabVIEWPing( pingResponse, sizeof(pingResponse) );     //&&&              // get ping response
      }
    }
  } else {
            if(debug) {
               Serial.println("\tERROR: No status response from radio");       // *** debug
            }
    }  
      
    if(debug) {
      Serial.print("Ping Byte 16 = ");
      Serial.print(pingResponse[16], HEX);
      Serial.print(", Byte 17 = ");
      Serial.println(pingResponse[17], HEX);
    }  
    if (pingResponse[16] == 0x4F && pingResponse[17] == 0x4B ) {            // response should be "OK" 
      ping_result = true;         // set ping to 1 = SUCCESS
      if (in_catch_up_mode){
        return ping_result;
      }
      if((last_file != file_num && in_catch_up_mode) 
              || last_file != 0 || last_file == file_num)
            {
             catch_up(file_num, packet_size, last_file);                     // go to catch_up function to send previous files
            }
            return ping_result;
      } else {
        ping_result = false;                                                // set ping to 0 = FAILURE  
          if(last_file == 0) {                                              // no response and this is first failed transmission 
              last_file = file_num;                                         // save file number that has not been sent
              EEPROM.write(2,last_file);
              EEPROM.write(1,file_num);
          }
        return ping_result;  
      }
}

void sendAlert() {

  uint8_t maint_mode[] = {  0x03, 0x00, 0xA0   };      // at byte 17,18 in receive string

  if( systemMaintMode )       // if system amintenance mode is enabled
     bitSet(modeBits, 1);
  if( !systemMaintMode)       // if system maintenance mode is clear
    bitClear(modeBits, 1);
  if( oilMaintMode ) 
    bitSet(modeBits, 2);
  if( !oilMaintMode )
    bitClear(modeBits, 2);  
  if( oilSensor ) 
    bitSet(modeBits, 0);
  if( !oilSensor )
    bitClear(modeBits, 0);  
  maint_mode[1] = modeBits;
  
  ZBTxRequest zbTx = ZBTxRequest( destination, maint_mode, sizeof(maint_mode) );        // message packet for 900 MHz radios and 64bit address 
//  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet

//  delay(5000);                      // small delay
  xbee.send(zbTx);                  //
  waitForSerial3data();  
  Serial3.flush();
}

void checkFileLimit() {
  if( (file_num == max_file_number && last_file == 0)             // delete files if over limit and all files have been sent
            || (file_num > low_limit && last_file == 0) )
          {
            delete_files(file_num); 
          } else if( file_num == max_file_number        // do not increment if over limit and transmission is down
                     && last_file != 0)
          {
            file_num = file_num;                      
            EEPROM.write(1,file_num);
          }if (file_num < max_file_number && !del_complete)      // increment file number if not over limit
    {                                      
     file_num++;                           // increment file number for next write
     EEPROM.write(1,file_num);
     }
}
