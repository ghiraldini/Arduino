#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
XBeeResponse response = XBeeResponse(); // declare response
ZBRxResponse rx = ZBRxResponse(); // declare response
int file_num = 1; // initalize file numbering
int last_file = 0; // global last sent transmission
int in_catch_up_mode; // flag to show in catch_up
int flow_out = 52; // RTS of VDIP
int time_date[5]; // array to save time and date
byte file_data; // variable to read serial
uint8_t f_data[33]; // array to save data from file
int max_file_number = 485; // when fileNumber = max_file_number go to delete_files

uint8_t data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x44, 0x7, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32}; // dummy info
int packet_size = sizeof(data);
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
  time_date[0] = year;
  time_date[1] = month;
  time_date[2] = day;
  time_date[3] = hour;
  time_date[4] = minute;
} 
void write_file(int fileNumber, uint8_t payload[], int packet_size){
  if (fileNumber > max_file_number){
    return;
  }
  delay(1000);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(fileNumber);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(1000);
  Serial2.print("WRF ");          // write to file once it is open (number = bits to write)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  for(int i = 0; i < packet_size; i++){
    Serial2.write(payload[i]);         // write data to file
    delay(500);
  }
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(fileNumber);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  delay(1000);
}  
int read_file(int fileNumber, int packet_size){
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
  Serial2.print("RDF ");           // Read from file xx (xx = number of bytes to read)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  delay(1500);
  Serial.print("Serial Input from VDIP: ");
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
    digitalWrite(flow_out, HIGH);   // set RTS high to prepare for closing file
    Serial2.print(13, BYTE);
  }
  delay(2000);
  digitalWrite(flow_out, LOW);      // reset RTS to low to close file
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(fileNumber);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
  Serial.println();
  Serial.print("F_Data: ");
  for (int k = 0; k < sizeof(f_data); k++){
    Serial.print(f_data[k], HEX);
  }
  Serial.println();
}
void send_xbee(uint8_t payload[], int fileNumber, int last_file_sent){
  int size = 33; // packet length
  Serial.print("Payload in XBEE send: ");
  for (int k = 0; k < sizeof(payload); k++){
    Serial.print(payload[k], HEX);
  }
  Serial.println();
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AD);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, payload, size);// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
  delay(10000);                     // small delay
  xbee.send(zbTx);                  // after sending a tx request, we expect a status response
  //  Serial.println("Sent");
  xbee.readPacket(5000);            // wait up to 5 seconds for the status response
  if (xbee.getResponse().isAvailable()){  // if there is a response, (there should always be one)
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){// got a response, should be a 0x8B 
      xbee.getResponse().getZBTxStatusResponse(txStatus);// send transmission status response (series 1)
      if (txStatus.getDeliveryStatus() == SUCCESS){ // get status response, if not SUCCESS, assume not sent | if SUCCESS and previous not sent
        if((last_file_sent != fileNumber && in_catch_up_mode == 1) || last_file_sent != 0 || last_file_sent == fileNumber){
          catch_up(fileNumber, last_file_sent);             // go to catch_up function to send previous files
        }
      } 
      else { // if not SUCCESS
        if(last_file_sent == 0){           // no response and this is first failed transmission 
          last_file_sent = fileNumber;     // save file number that has not been sent to local variable
          last_file = last_file_sent;      // save file to global variable 
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
    //    Serial.print("Done deleting files.");
  } 
  else {
    exit; // not all data sent, do not delete
  }
}
byte catch_up(int fileNumber, int last_file_update){// send all failed transmission files
  if(last_file_update != fileNumber && last_file != 0){   // send from first non sent file to present file
    in_catch_up_mode = 1;           // set to 1, so send_xbee is not in infinite loop
    read_file(last_file_update, packet_size);    // read first non sent file
    last_file_update++;             // increment non sent file number
    send_xbee(f_data, fileNumber, last_file_update);// send file
  }
  else{
    in_catch_up_mode = 0;           // set back to zero after catch up is done
    last_file_update = 0;           // set back to zero after catch up is done
    last_file = last_file_update;   // set global to zero
    if (fileNumber > max_file_number){// all files have been sent, check to see if over limit
      delete_files(fileNumber);     // if yes, delete all files while transmission is good
    }
  }
}
//-----------------------------------------------------------------------------------------
//byte ping_labview(){
//}
//-----------------------------------------------------------------------------------------
void maintenance_mode(){
  Serial.print("IN MAINTENANCE MODE");
  uint8_t maint_mode[] = {
    0x00  };
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, maint_mode, sizeof(maint_mode));// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
  delay(3000);                      // small delay
  xbee.send(zbTx);                    // after sending a tx request, we expect a status response
}


void setup(){
  Wire.begin();
  pinMode(flow_out, OUTPUT);        // set the RTS of VDIP as output
  attachInterrupt(0, maintenance_mode, CHANGE);// Interrupt for maintenance mode (0 = pin2)
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
  if(Serial.available()){
    int incomingByte = Serial.read();// start execution through serial monitor for testing purposes
    if (incomingByte == '1'){ // send "1" to start loop
      //      get_date();
      uint8_t data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x44, 0x7, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32}; // dummy info
      int packet_size = sizeof(data);
      Serial.print("Packet Size: ");
      Serial.println(packet_size);
      //--------------------------------------------------Call Inverter---------------------//F
      //--------------------------------------------------Call Time Stamp-------------------//U
      //                                                                                    //N
      //                                                                                    //C
      //                                                                                    //T
      //                                                                                    //I
      write_file(file_num, data, packet_size);//-----------------------Write to file---------------------//O
      //--------------------------------------------------Call PING LabVIEW-----------------//N
      delay(1000);
      read_file(file_num, packet_size);
      delay(1000);
      send_xbee(f_data, file_num, last_file);//-------------Send Info over Xbee---------------//S
      //      Serial.println("Sending");
      if (file_num > max_file_number && last_file == 0){
        delete_files(file_num);// delete files if over limit and all files have been sent
      } 
      else if (file_num > max_file_number && last_file != 0){
        file_num = file_num;// do not increment if over limit and transmission is down
      } 
      else if (file_num < max_file_number){// increment file number if not over limit
        file_num++; // increment file number for next write
      }
      //      delay(10000); // loop delay [3,600,000 = 1Hr, 1,800,000 = 30min]
    }
  }
}



