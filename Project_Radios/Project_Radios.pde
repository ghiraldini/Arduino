#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
XBeeResponse response = XBeeResponse(); // declare response
ZBRxResponse rx = ZBRxResponse(); // declare response
int file_num = 1; // initalize file numbering
int last_file; // global last sent transmission
int in_catch_up_mode; // flag to show in catch_up
int flow_out = 52; // CTS of VDIP
int time_date[6]; // array to save time and date
char file_data; // variable to read serial
uint8_t f_data[46]; // array to save data from file
int max_file_number = 15; // when fileNumber = max_file_number go to delete_files
//-----------------------------------------------------------------------------------------------------------------------
byte bcdToDec(byte val){
  return ( (val/16*10) + (val%16) );
}
unsigned long get_date(){            
  Wire.beginTransmission(DS1307_I2C_ADDRESS);   // transmit to device #104, the ds 1307
  Wire.send(0x00);                              // resets ds1307 to beginning of its registers - could be in setup, 
                                                // but this just makes sure that whenever you are going to do 
                                                // a reading it is starting from the right point
  Wire.endTransmission();                       // stop transmitting
  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);      // request 7 bytes from slave ds1307, we'll assume it'll send them all
                                                // even though it doesn't have to
  int second = bcdToDec(Wire.receive() & 0x7f); // I have declared all these in here so that the
  int minute = bcdToDec(Wire.receive());        // function is self contained
  int hour = bcdToDec(Wire.receive() & 0x3f);   // you could declare them at the top and then get at
  int day_of_week=bcdToDec(Wire.receive());     // the bits individually elsewhere in the code
  int day = bcdToDec(Wire.receive());           // but this could make the code less logical and
  int month = bcdToDec(Wire.receive());         // more difficult to debugg  
  int year = bcdToDec(Wire.receive());  
  time_date[0] = hour;
  time_date[1] = minute;
  time_date[2] = month;
  time_date[3] = day;
  time_date[4] = year;
  time_date[5] = day_of_week;
} 
long int write_file(int fileNumber, uint8_t data[]){
  get_date();
  delay(1000);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(fileNumber);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(2000);
  Serial2.print("WRF 41");          // write to file once it is open
  Serial2.print(13, BYTE);
  for(int j = 0; j<6; j++){
    Serial2.print(time_date[j]);    // write time/date stamp
    delay(500);
  }
  Serial2.print("-");               // separate time/date and data with dash
  delay(100);
  for(int i = 0; i<32; i++){
    Serial2.print(data[i], BYTE);   // write data to file
    delay(500);
  }
  Serial2.print(13, BYTE);
  delay(2000);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(fileNumber);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  delay(2000);
}  
int read_file(int fileNumber){
  int i = 0;                        // declare and initialize pointer for reading file
  int index = 0;
  delay(500);
  Serial2.print("OPR ");            // open file for reading
  Serial2.print(fileNumber);
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.flush();                  // clean out serial buffer
  Serial2.print("SEK ");            // set pointer of file to read
  Serial2.print(i);
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.print(13, BYTE);            
  Serial2.print("RDF 41");           // Read from file xx (xx = number of bytes to read)
  Serial2.print(13, BYTE);
  delay(1500);
  while (Serial2.available()){      // set loop to read all bytes in buffer
    file_data = Serial2.read();     // read serial buffer
    while (file_data!=68 && file_data!=58 && file_data!=92 && file_data!=62){    // filter out command prompt "D:\>"
      f_data[index] = file_data;    // save data to array
      index++;                      // increment array index
      if (file_data == 68)          // break out of loop when command prompt appears again "D"
        Serial2.flush();            // flush buffer and break
      break;      
    }
    digitalWrite(flow_out, HIGH);   // set CTS high to prepare for closing file
    Serial2.print(13, BYTE);
  }
  delay(2000);
  digitalWrite(flow_out, LOW);      // reset CTS to low to close file
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(fileNumber);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
}
byte send_xbee(uint8_t payload[], int fileNumber, int last_file_sent){
  int size = 43;
//  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x402CE5A2);// 64 bit addressing (MY Xbee Radios)
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, payload, size);// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
 
  delay(10000);                     // small delay
  xbee.send(zbTx);                    // after sending a tx request, we expect a status response
  Serial.println("Data Sent");
  xbee.readPacket(5000);            // wait up to 5 seconds for the status response
  Serial.println("Reading packet");
  if (xbee.getResponse().isAvailable()){  //-----change from here-----    
    Serial.println("Got a Response");
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){// got a response, should be a tx status (zb for series 2)
      Serial.println("ZB_TX_STATUS_RESPONSE");   
      xbee.getResponse().getZBTxStatusResponse(txStatus);// send transmission status response (series 1)
      Serial.print("TX Status = ");
      Serial.println(ZB_TX_STATUS_RESPONSE, HEX); // 0x89 or 0x8B(series 2)
      //Serial.print("Last File Sent = ");
      //Serial.println(last_file_sent);
      if (txStatus.getDeliveryStatus() == SUCCESS){ // get status response (command only for series 1)
        Serial.println("SUCCESS!!!");
        if((last_file_sent != fileNumber && in_catch_up_mode == 1) || last_file_sent != 0 || last_file_sent == fileNumber){
        Serial.print("Go to catch_up & start at file = ");// got a response and previous files have not been sent
        Serial.println(last_file_sent);                   // or go to catch up to clear variables if (last = file#)
        catch_up(fileNumber, last_file_sent);             // go to catch_up function to send previous files
        }
      } else { 
        Serial.println("No Response...");
        if(last_file_sent == 0){           // and this is first failed transmission 
        last_file_sent = fileNumber;       // save file that has not been sent
        Serial.print("Save last file = ");
        Serial.println(last_file_sent);
        last_file = last_file_sent;        // save file to global variable 
        }
      }
    }
  delay(1000);
  }
}
byte delete_files(int fileNumber){
  if(last_file == 0){                     // only delete if all files have been sent
    for(int i = 1; i < fileNumber+1; i++){// delete all files starting from fileNumber = 1
    Serial2.print("DLF ");
    Serial2.print(i);
    Serial2.print(".TXT");
    Serial2.print(13, BYTE);
    }
    Serial.print("Done deleting files.");
  }
}
byte catch_up(int fileNumber, int last_file_update){// send all failed transmission files
//Serial.println("In Catch Up Function");
//Serial.print("fileNumber = ");
//Serial.println(fileNumber);
//Serial.print("last_file_update = ");
//Serial.println(last_file_update);
  if(last_file_update != fileNumber && last_file != 0){   // send from first non sent file to present file
    in_catch_up_mode = 1;           // set to 1, so send_xbee is not in infinite loop
    read_file(last_file_update);    // read first non sent file
    last_file_update++;             // increment non sent file number
    send_xbee(f_data, fileNumber, last_file_update);// send file
  }else{
    in_catch_up_mode = 0;           // set back to zero after catch up is done
    last_file_update = 0;           // set back to zero after catch up is done
    last_file = last_file_update;   // set global to zero
    if (fileNumber > 100){          // all files have been sent, check to see if over limit
      delete_files(fileNumber);     // if yes, delete all files while transmission is good
    }
  }
}
void setup(){
  Wire.begin();
  pinMode(flow_out, OUTPUT);        // set the CTS of VDIP as output
  xbee.begin(9600);                 // start xbee
  Serial.begin(9600);               // start serial - for debugging
  Serial2.begin(9600);              // start serial#2 - for VDIP1
  Serial3.begin(9600);              // start serial#3 - for Xbee
  Serial2.print("IPA");             // sets the vdip to use ascii numbers 
  Serial2.print(13, BYTE);          // return character to tell vdip its end of message
  Serial.println("Ready");
  Wire.beginTransmission(DS1307_I2C_ADDRESS);        
}
void loop(){
  uint8_t data[] = {"1234567891011121314151617181920"}; // dummy info
  if(Serial.available()){
    int incomingByte = Serial.read();
    if (incomingByte == '1'){
      for(int k = 1; k < 3; k++){ // set loop for functions
        write_file(file_num, data);//---------------------Write to file---------------------
        read_file(file_num);//-----------------------------Read file--------only to get time/date to differentiate files for testing
//        Serial.print("""Last_File"" being sent to Xbee function = ");
//        Serial.println(last_file);
        send_xbee(f_data, file_num, last_file);//-----------Send Info over Xbee---------------
//        Serial.print("Last_file"" after Xbee_send function = ");
//        Serial.println(last_file);
        file_num++; // increment file number for next write
        if (file_num > 100){
          delete_files(file_num);// delete files if over limit
        }
        delay(10000); // small delay
      }
    }
  }
}
