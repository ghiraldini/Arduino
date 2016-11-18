/*
I left all your functions out of this for my testing cause i didnt want to mess with them.  
The serial read helper functions work like a charm though!
I saw the ping give up after 30seconds so that worked perfectly.

I changed minor things to fit my set up.

I was able to send the ping and the data strings multiple times.

I have changed the delete files function just a little and it works for the small delete for now.  I could not
test the big delete cause i could not test the catch up. (read below)

I dont know if you had this same problem Bill, but I had to add a termination byte at the end of the 
strings being sent or else labview was being a pain in the ass.

i also made some modifications to the labview, but those might not be necessary if you didn't have the problem of reading
different size incoming buffer sizes??

On the labview ping response string the last two bytes were being cutoff, so i modified that.
i think it only mattered for the serial printing part of it and not the ping result??

I verified that the ping works when labview is running and says failure when it is not, I'm sure you did to Bill.

It's going to be hard to test the catch up function cause everytime i pulled the plug on the xbee to labview
i would get an error on labview that would not let me click out of it.  i would have to ctrl-alt-del to end labview
and restart the VI.  This might be a problem if they ever pull the plug on accident.  We should make a note of that in
the trouble shooter.

I think the catch up should work, but i could not verify that tonight.  I made some changes in the loop for the catch up function 
to make sure all the files were sent.

Email me if you have any questions.  i'll be at school around 12:50ish.

*/

// ------------------------------------------------------------------------------- Required Libraries
#include "XBee.h"                                 // Library for Xbee Communication
#include "Wire.h"                                 // Library for Real Time Clock
#include <EEPROM.h>                               // Library to allow writing variables to EEPROM
#define DS1307_I2C_ADDRESS 0x68                   // This is the I2C address of Real Time Clock  

// ------------------------------------------------------------------------------- Operational Tweaks
// Change these parameters to modify behavior of system
const unsigned long POLLMINUTES = 1;                                       // set interval for reading inverter data in minutes

const int s1len = 40;                                                      // size of temp array to hold bytes from swca
unsigned long maxWait = 30000;                                             // milliseconds to wait for data from serial port 1 
unsigned long minWait = 30000;                                             // milliseconds for smaller wait for serial 1 data 
unsigned long xbWait =  20000;                                             // milliseconds to wait for response from XBee/LabVIEW  
int BETWEENMENUS = 50;                                                     // milliseconds to pause between successive menu item requests to SWCA
int max_file_number = 15;                                                  // when fileNumber = max_file_number go to delete_files
bool debug = true;                                                         // turn on debug output to serial console
int systemMaint = 40;                                                      // digital pin for system maintenance mode switch
int maintLED = 32;                                                         // digital pin for maintenance status LED

// -------------------------------------------------------------------------------- End of Operational Parameters

// -------------------------------------------------------------------------------- XBee radio vars

uint8_t TX_payload[33];                                                             // results from polling inverter  
//  XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x403A34AC);            // 64 bit address of Project Base 900MHz radio 
//  XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x40547B54);            // 64 bit address of Bill's Base 900MHz Radio  
XBeeAddress64 destination =   XBeeAddress64(0x0013A200, 0x403A34AC);                // 64 bit address of Jason's Base 900MHz Radio  
//  ZBTxRequest zbTx = ZBTxRequest(destination, payload, sizeof(payload));          // project message packet
//  ZBTxRequest zbTx_BC = ZBTxRequest( BC_addr64, TX_payload, sizeof(TX_payload));  // message packet for Bills radios
ZBTxStatusResponse txStatus = ZBTxStatusResponse();                                 // transmit response packet
//  XBeeResponse response = XBeeResponse();                                         // Declare response for Series 1 packet typ

ZBRxResponse rx = ZBRxResponse();                                                   // declare response for Digimesh packet type   
XBee xbee = XBee();                                                                 // Declare an instance of the XBee class     

// -------------------------------------------------------------------------------- Jason's vars

int ping_result;// status from labview ping

int file_num;                                     // initalize file numbering for USB stick
int last_file;                                    // global last sent transmission
int in_catch_up_mode;                             // flag to show in catch_up, i.e files saved but not transmitted to base
int vdip_rts = 52;                                // CTS of VDIP
int time_date[5];                                 // array to save time and date
byte file_data;                                   // variable to read serial
uint8_t f_data[33];                               // array to save data from file


// --------------------------------------------------------------------------------- General Constants
const byte MENULEFT =  0x4C;       // ascii (76d) = 'L'
const byte MENURIGHT = 0x52;       // acsii (82d) = 'R'
const byte MENUUP =    0x55;       // ascii (85d) = 'U'
const byte MENUDOWN =  0x44;       // ascii (68d) = 'D'
const int START = 1;               // used as a flag for timeout function
const int CHECK = 2;               // used as a flag for timeout function
const int STOP = 3;                // used as a flag for timeout function
unsigned long elapsedTime;         // used by timeout function
unsigned long startTime;           // used by timeout function
int maintMode;                     // system status switch position
byte modeBits;                     // byte for alert message byte 2

// --------------------------------------------------------------------------------- Menu validation hash codes

// The following validation strings are hash values based on the sum of the first
// 14 ascii characters received after the flag sequence 0x80 0xE0 in response to a menu navigation command.
// The hash sum is found as the lowest two bytes of the HEX sum
// note: sizeof() will not return the literal number of bytes in the array because the hex values are two bytes each.

uint16_t hashGenTop[] =   { 0x54C };                                                          // Generator Menu 2.0
uint16_t hashHome[] =     { 0x513 };                                                          // Generator Menu 2.1 
uint16_t hashMeterTop[] = { 0x880 };                                                          // Meter Menu 4.0
uint16_t hashErrorTop[] = { 0x4CE };                                                          // Error Menu 5.0
uint16_t hashGen[] =      { 0x543, 0x581, 0x584, 0x4F2, 0x4EC, 0x520, 0x566};                 // Generator Menu 2.2 - 2.8
uint16_t hashMeters[] =   { 0x583, 0x330, 0x2C0, 0x575, 0x543, 0x40F, 0x32C, 0x4A5, 0x54E };  // Meters Menu 2.1 - 2.9
uint16_t hashErrors[] =   { 0x4DF, 0x4F3, 0x3F7, 0x4BB, 0x48D, 0x574 };                       // Errors Menu 2.1 - 2.6

// ---------------------------------------------------------------------------------- General variables and flags

byte swcaInit[] = { 0x1, 0xE3, 0x4C };              // SWCA initialization string
byte s1Data[s1len];                                 // container for incoming serial port 1 data                                                     
byte extractedData[] = { 0x20, 0x20, 0x20, 0x20 };  // container for extracted menu data to be inserted into TX_payload                                             
unsigned long pollInterval;                         // The calculated polling interval in milliseconds
unsigned long elapsed = 0;                          // timer for polling cycle
unsigned long checkelapsed = 0;                     // calculated elapsed time var
unsigned long start = 0;                            // begin time in millis for calculating polling interval
bool startcycle = true;                             // flag to manage polling interval
byte ledStatus = B00000000;

// -------------------------------------------------------------------------------- Debug variables can be removed from final
int debugTally;            // *** debug code
uint16_t *debugHash;       // *** debug code

// ----------------------------------------------------------------------------------- Program loops
void setup() {

  Serial.begin(9600);                   // Initialize serial port 0 for troubleshootong
  Serial1.begin(9600);                  // Port 1 for SWCA adapter
  Serial2.begin(9600);                  // Port 2 for VDIP USB storage
  Serial3.begin(9600);                  // Port 3 for XBee radio  
  //    xbee.begin(9600);                     // start xbee
  Wire.begin();
  //    Wire.beginTransmission(DS1307_I2C_ADDRESS);        

  pollInterval = POLLMINUTES*60*1000;   // Calculate polling interval in milliseconds
  start = millis();                     // log starting time for polling interval

  pinMode(systemMaint, OUTPUT);         // initialize port for pullup mode
  digitalWrite(systemMaint, HIGH);      // enable 20K pullup resistor
  pinMode(systemMaint, INPUT);          // once pullup is enabled redefine port to read switch state
  pinMode(maintLED, OUTPUT);            // set pin for simple output
  pinMode(vdip_rts, OUTPUT);            // set the CTS of VDIP as output
  Serial2.print("IPA");               // sets the vdip to use ascii numbers 
  Serial2.print(13, BYTE);            // return character to tell vdip its end of message
  file_num = EEPROM.read(1);          // Get stored values for file system naming
  last_file = EEPROM.read(2);
  delay(3000);  // *** short delay to insert disk or flip maint switch
  maintLED = digitalRead(systemMaint);
  if (maintLED == LOW){
    delete_files(file_num);
    EEPROM.write(1,1);
    EEPROM.write(2,0);
  }
}
//---------------------------------------------------------------------------------------------LOOP
void loop() {
  if (Serial.available()){
    byte input = Serial.read();
    if (input == '1'){
      for(int j = 0; j < 10; j++){
        uint8_t TX_payload[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32, 0xA0  };
//        Serial.print("Size of Payload: ");
//        Serial.println(sizeof(TX_payload));
        
        write_file(file_num, TX_payload, sizeof(TX_payload));
        if( ping_labview(sizeof(TX_payload)) ) {                           // make sure LabVIEW is online and responding
          send_xbee(TX_payload, sizeof(TX_payload), file_num, last_file);    // Send extracted polling data to Base Station
          
          Serial.print("File Sent: ");
          Serial.println(file_num);
          if( debug ) {
            Serial.println("LabVIEW Ping & Data SUCCESS");
//            if((last_file != file_num && in_catch_up_mode == 1) || last_file != 0 || last_file == file_num){
//              catch_up(file_num, sizeof(TX_payload), last_file);             // go to catch_up function to send previous files
//            } 
          }  
        } else {
          if(debug) {
            Serial.println("ERROR: LabVIEW ping failed");
          }
        }
      if( (file_num > max_file_number) || (file_num > 10 && last_file == 0) )             // delete files if over limit and all files have been sent      
      {
        delete_files(file_num);                    
        Serial.print("File Number after deleting: ");
        Serial.println(file_num);
      } 
      else if( file_num > max_file_number        // do not increment if over limit and transmission is down
      && last_file != 0)
      {
        file_num = file_num;                      
        EEPROM.write(1,file_num);
      } 
      else if (file_num < max_file_number)      // increment file number if not over limit
      {                                      
        file_num++;                           // increment file number for next write
        EEPROM.write(1,file_num);
      }
    }
  Serial.print("File number = ");    //  *** debug
  Serial.println(file_num);
  Serial.print("Last file = ");
  Serial.println(last_file);
  Serial.print("Max file = ");      // *** mode debug
  Serial.println(max_file_number);
  }
  }
}
//------------- A time limited loop that waits up to maxWait milliseconds for data to arrive in serial 1 buffer
bool waitForSerial3data() {

  unsigned long beginWait = millis();                            // record current millis for start of wait
  unsigned long elapsed = 0;                                     // elapsed time

  while(!Serial3.available()) {                                  // loop until there is data to be read or timeout
    delay(10);                                                   // A short delay to allow for forced breaks
    elapsed = millis() - beginWait;                              // calculate timeout
    if(elapsed > xbWait)                                        // exit if no serial data has arrived
      return false;                                              // no serial data has arrived
  }
  return true;                                                    // data has been detected in serial port 1
} 


//-------------- Read LabVIEW ping response received at the serial buffer
bool readLabVIEWPing(byte *sDat, int sDatLen) {               // General serial read routine for SWCA port

  byte rcvByte = 0x0;                                         // var to hold each byte value from serial buffer 

  if(waitForSerial3data()) {                                  // hangout till serial data arrives
    timeout( START );                                         // data has arrived so start safety timer to prevent buffer underrun infinite loop
    Serial.print("search for 7E :");  // *** debug 
    do {                                                      // Look for ***
      if( timeout(CHECK) ) {
        timeout( STOP );
        return false;
      }
      rcvByte = Serial3.read();

      Serial.print(rcvByte, HEX); // *** debug
    } 
    while(rcvByte != 0x7E);                                 // Read bytes until start delimiter (0x7E) is found
    Serial.println();   // *** debug


    for(int i = 0; i < sDatLen+2; i++ ) {                       // Read bytes from serial port 3
      rcvByte = Serial3.read(); 
      Serial.print(rcvByte, HEX);
      sDat[i] = rcvByte;                                       // fill array with received bytes
      delay(100);                                                // delay needed because ***
    }
    if(debug) {                                         // *** debug code
      //Serial.print(" Ping response: ");
      writeHexArray(0, sDat, sizeof(sDat));
    }
    if(debug) {
      Serial.println("LabVIEW ping OK ");        // *** debug
    }
    return true;                                              // flags were found and data read
  }
  if(debug) {
    Serial.println("\tERROR - Timed out waiting for LabVIEW  ");        // *** debug
  }
  return false;                                               // No serial data to validate
}

//----------------- Helper function to print an array to a serial port
void writeHexArray(int port, byte *array, int arrayLen) {      

  switch (port) {
  case 0:                                                  // Used to print mix of ascii chars and hex values to serial console
    for( int i = 0; i < arrayLen; i++) {
      if( array[i] > 0x1F && array[i] < 0x7F ) {            // if printable alpha/numeric ascii code
        Serial.print(array[i]);                             // print character instead of hex value
      } 
      else {
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

//---------------------- a simple function to check for timeout based on minWait
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
  }
  return false;
}  

// Jason's functions start here << --------------------------------------------------------------------------

void write_file(int file_num, uint8_t *payload, int packet_size){
  if( debug) {  
    Serial.print("File number = ");    //  *** debug
    Serial.print(file_num);
    Serial.print(", Last file = ");
    Serial.print(last_file);
    Serial.print(", Max file = ");      // *** mode debug
    Serial.print(max_file_number);
    Serial.print(", Packet size = ");
    Serial.println(packet_size);
  }
  if (file_num > max_file_number){
    return;
  }
  Serial2.print("OPW ");           // open/create file for writing
  Serial2.print(file_num);         // file number to open/create
  Serial2.print(".TXT ");          // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(500);
  Serial2.print("WRF ");           // write to file once it is open (number = bits to write)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  for(int i = 0; i < packet_size; i++) {
    Serial2.write(payload[i]);     // write data to file
    delay(50);
  }
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(file_num);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
} 

int read_file(int file_num2, int packet_size){
  Serial.print("Reading File: ");
  Serial.println(file_num2);
  int i = 0;                        // declare and initialize pointer for reading file
  int index = 0;
  delay(500);
  Serial2.print("OPR ");            // open file for reading
  Serial2.print(file_num2);
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.flush();                  // clean out serial buffer
  Serial2.print("SEK ");            // set pointer of file to read
  Serial2.print(i);
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.print(13, BYTE);            
  Serial2.flush();
  Serial2.print("RDF ");           // Read from file xx (xx = number of bytes to read)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  delay(1500);
  Serial.print("Serial input from VDIP: ");
  while (Serial2.available()){      // set loop to read all bytes in buffer
    file_data = Serial2.read();     // read serial buffer
    Serial.print(file_data, HEX);
    while (file_data!=0x44 && file_data!=0x3A && file_data!=0x5C && file_data!=0x3E && file_data!=0x0D){    // filter out command prompt "D:\>"
      f_data[index] = file_data;    // save data to array
      index++;                      // increment array index
      if (file_data == 0x44 || file_data == 0x0D)          // break out of loop when command prompt appears again "D"
        Serial2.flush();            // flush buffer and break
      break;      
    }
    digitalWrite(vdip_rts, HIGH);   // set RTS high to prepare for closing file
    Serial2.print(13, BYTE);
  }
    delay(2000);
    Serial.println();
    Serial.print("Data read from VDIP: ");
    for(int k = 0; k < packet_size; k++){
      Serial.print(f_data[k], HEX);
    }
  Serial.println();
  delay(2000);
  digitalWrite(vdip_rts, LOW);      // reset RTS to low to close file
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(file_num2);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
}

void send_xbee(uint8_t payload[], int packet_size, int file_num1, int last_file1) {    
Serial.print("VDIP Data in XBEE send: ");
 for(int k = 0; k < packet_size; k++){
      Serial.print(f_data[k], HEX);
    }
    Serial.println();
    Serial.print("Packet size in XBEE Send: ");
    Serial.println(packet_size);
  ZBTxRequest zbTx = ZBTxRequest(destination, payload, packet_size);// message packet 

  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet 

  delay(1000);                     // small delay
  xbee.send(zbTx);                                                // after sending a tx request, we expect a status response
  xbee.readPacket(5000);                                          // wait up to 5 seconds for the status response
  if (xbee.getResponse().isAvailable()){                          // look for response, 
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){  // verify that response packet ID is type 0x8B 
      xbee.getResponse().getZBTxStatusResponse(txStatus);         // if so, get embedded status bytes from frame
      if (txStatus.getDeliveryStatus() == SUCCESS){               // extract response status byte 9, if not SUCCESS (byte 9 = 0), assume not sent | if SUCCESS and previous not sent
      Serial.println("Data Sent");
      Serial.print("File Number: ");
      Serial.println(file_num);
      Serial.print("Last File Sent: ");
      Serial.println(last_file1);
//      if (last_file1+1 == file_num1){
//        return;
//      }
        if((last_file1 != file_num1 && in_catch_up_mode == 1)
          || last_file1 != 0 || last_file1 == file_num1)
        {
          if (in_catch_up_mode == 1 || last_file1+1 == file_num1){
          last_file1++;
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
    delay(1000);
  }
}

byte delete_files(int file_number1){
  Serial.println("Deleting Files");
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
  } 
}

byte catch_up(int file_number, int packet_size, int last_file_update){    // send all failed transmission files
Serial.println("Catching Up!");
  if(last_file_update != file_number && last_file_update != 0){           // send from first non sent file to present file
    in_catch_up_mode = 1;                                                 // set to 1, so send_xbee is not in infinite loop
    read_file(last_file_update, packet_size);                      // read first non sent file
    delay(5000);
    Serial.print("VDIP Data in Catch up: ");
    for(int k = 0; k < packet_size; k++){
      Serial.print(f_data[k], HEX);
    }
    Serial.println();
    Serial.print("Send last bad TX file number: ");
    Serial.println(last_file_update);
    send_xbee(f_data, sizeof(f_data), file_number, last_file_update);        // send file
  }
  else{
    Serial.println("Done catching up!");
    in_catch_up_mode = 0;                                               // set back to zero after catch up is done
    last_file_update = 0;                                               // set back to zero after catch up is done
    last_file = last_file_update;                                       // set global to zero
    file_num = file_number;
    Serial.print("File Number after catch up: ");
    Serial.println(file_number);
    Serial.print("Last File after catch up: ");
    Serial.println(last_file);
    EEPROM.write(1, file_number);
    EEPROM.write(2, last_file);
    if (file_number > max_file_number || file_number > 10)  {                 // all files have been sent, check to see if over limit
      delete_files(file_number);                                           // if yes, delete all files while transmission is good
    }
  }
}

//-----------------------------------------------------------------------------------------
int ping_labview(int packet_size) {
  uint8_t ping[] = { 0x02, 0x4F, 0x4B, 0xA0 };                                       // payload - message type 2 for XBee API type 0x10 zbTx payload 
  uint8_t pingResponse[] = { 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00   };                                         // response string from zbResponse        
  bool ping_result;                                                          // status from labview ping response

  ZBTxRequest zbTx = ZBTxRequest( destination, ping, sizeof(ping) );        // message packet for 900 MHz radios and 64bit address 

  //  delay(5000);                                                            // small delay

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
        readLabVIEWPing( pingResponse, sizeof(pingResponse) );                   // get ping response
      }
    }
  } 
  else {
    if(debug) {
      Serial.println("\tERROR: No status response from radio");       // *** debug
    }
  }  
  Serial.print("Byte 16: ");
  Serial.println(pingResponse[16], HEX);
  Serial.print("Byte 17: ");
  Serial.println(pingResponse[17], HEX);

  if (pingResponse[16] == 0x4F && pingResponse[17] == 0x4B ) {        // response should be "OK" 
    ping_result = true;                                               // set ping to 1 = SUCCESS
    if((last_file != file_num && in_catch_up_mode == 1) 
      || last_file != 0 || last_file == file_num)
    {
      catch_up(file_num, packet_size, last_file);                     // go to catch_up function to send previous files
    }
    return ping_result;
  } 
  else {
//    Serial.println(ping_result);
    ping_result = false;                                              // set ping to 0 = FAILURE  
    if(last_file == 0) {                                              // no response and this is first failed transmission 
      last_file = file_num;                                           // save file number that has not been sent
      EEPROM.write(2,last_file);
      EEPROM.write(1,file_num);
    }
    return ping_result;  
  }
}



