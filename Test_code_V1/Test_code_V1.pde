#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#include "EEPROM.h" // Library to save pointers/variables
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
XBeeResponse response = XBeeResponse(); // declare response
ZBRxResponse rx = ZBRxResponse(); // declare response
int file_num; // initalize file numbering
int last_file; // global last sent transmission
int in_catch_up_mode; // flag to show in catch_up
int vdip_rts = 52; // RTS of VDIP connected to pin 52 (36 for Bill's setup)
int time_date[5]; // array to save time and date
char file_data;
int max_file_number = 485; // when fileNumber = max_file_number go to delete_files
uint8_t Tx_payload[] = { 
  0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x04, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x35, 0x37, 0x38, 0x39, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49}; // dummy info
//--------------------------------------------Bill's variable for Packet - delete when merging code
uint8_t f_data[32]; // array to save data from file
byte data_in[20];// length of received string from labview ping response
int ping_result;// status from labview ping
int maint_switch = 40;// maintenance switch connected to digital pin 40
unsigned long int max_time = 40000;
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
void write_file(int file_num, uint8_t Tx_payload[], int packet_size){
  if (file_num > max_file_number){
    return;
  }
  delay(1000);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(file_num);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(1000);
  Serial2.print("WRF ");          // write to file once it is open (number = bits to write)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  for(int i = 0; i < packet_size+1; i++){
    Serial2.write(Tx_payload[i]);         // write data to file
    delay(500);
  }
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(file_num);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  delay(1000);
}  
int read_file(int file_num, int packet_size){
  int i = 0;                        // declare and initialize pointer for reading file
  int index = 0;
  delay(500);
  Serial2.print("OPR ");            // open file for reading
  Serial2.print(file_num);
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
  while (Serial2.available()){      // set loop to read all bytes in buffer
    file_data = Serial2.read();     // read serial buffer
    while (file_data!=68 && file_data!=58 && file_data!=92 && file_data!=62){    // filter out command prompt "D:\>"
      f_data[index] = file_data;    // save data to array
      index++;                      // increment array index
      if (file_data == 68)          // break out of loop when command prompt appears again "D"
        Serial2.flush();            // flush buffer and break
      break;      
    }
    digitalWrite(vdip_rts, HIGH);   // set RTS high to prepare for closing file
    Serial2.print(13, BYTE);
  }
  delay(2000);
  digitalWrite(vdip_rts, LOW);      // reset RTS to low to close file
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(file_num);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
}
byte send_xbee(uint8_t Tx_payload[], int packet_size, int file_num, int last_file){
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, Tx_payload, packet_size);// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
  delay(10000);                     // small delay
  xbee.send(zbTx);                  // after sending a tx request, we expect a status response
  xbee.readPacket(5000);            // wait up to 5 seconds for the status response
  if (xbee.getResponse().isAvailable()){  // if there is a response, (there should always be one)
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE){// got a response, should be a 0x8B 
      xbee.getResponse().getZBTxStatusResponse(txStatus);// send transmission status response (series 1)
      if (txStatus.getDeliveryStatus() == SUCCESS){ // get status response, if not SUCCESS, assume not sent | if SUCCESS and previous not sent
        if((last_file != file_num && in_catch_up_mode == 1) || last_file != 0 || last_file == file_num){
          catch_up(file_num, packet_size, last_file);// go to catch_up function to send previous files
        }
      } 
      else { // if not SUCCESS
        if(last_file == 0){                // no response and this is first failed transmission 
          last_file = file_num;            // save file number that has not been sent to local variable
          EEPROM.write(2,last_file);
          EEPROM.write(1,file_num);
        }
      }
    }
    delay(1000);
  }
}
byte delete_files(int file_num){
  if(last_file == 0){                     // only delete if all files have been sent
    for(int i = 1; i < file_num+1; i++){// delete all files starting from fileNumber = 1
      Serial2.print("DLF ");
      Serial2.print(i);
      Serial2.print(".TXT");
      Serial2.print(13, BYTE);
    }
  } 
  EEPROM.write(1, 1);// save file number to EEPROM = 1
  EEPROM.write(2, 0);// save last file sent to EEPROM = 0
}
byte catch_up(int file_num, int packet_size, int last_file_update){// send all failed transmission files
  if(last_file_update != file_num && last_file != 0){   // send from first non sent file to present file
    in_catch_up_mode = 1;           // set to 1, so send_xbee is not in infinite loop
    read_file(last_file_update, sizeof(Tx_payload));    // read first non sent file
    last_file_update++;             // increment non sent file number
    send_xbee(f_data, packet_size, file_num, last_file_update);// send file
  }
  else{
    in_catch_up_mode = 0;           // set back to zero after catch up is done
    last_file_update = 0;           // set back to zero after catch up is done
    last_file = last_file_update;   // set global to zero
    EEPROM.write(1, file_num);
    EEPROM.write(2, last_file);
    if (file_num > max_file_number || file_num > 100){// all files have been sent, check to see if over limit
      delete_files(file_num);     // if yes, delete all files while transmission is good
    }
  }
}
//-----------------------------------------------------------------------------------------
byte ping_labview(int packet_size){
  Serial.println("Pinging");
  byte string_in;
  //  unsigned long begin_wait = millis();
  //  unsigned long elapsed = 0;
  uint8_t ping[] = {
    0x02, 0x4F, 0x4B                          };
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, ping, sizeof(ping));// message packet
  delay(1000);                      // small delay
  xbee.send(zbTx);                  // after sending ping, we expect "OK" response
  Serial.println("Ping Sending");
  delay(100);
  //--------------------read loop-----------
  Serial.println("Reading");  
  int i = 0;
  int j = 0;
  while(millis() < max_time){
    string_in = Serial3.read();
    if(string_in == 0x7E){
      for (int j = 0; j < 21; j++){
        data_in[j] = Serial3.read();
      }
    }
    if(string_in == 0xD3){
      Serial.println("end of string");
      break;
    }
    i++;
  }
  for(int k = 0; k < 21; k++){
    Serial.print(data_in[k], HEX);
  }
  if (data_in[17] == 79 && data_in[18] == 75){//79 = 'O', 75 = 'K'
    ping_result = 1;//set ping to 1 = SUCCESS
    Serial.println("SUCCESS");
    if((last_file != file_num && in_catch_up_mode == 1) || last_file != 0 || last_file == file_num){
      catch_up(file_num, packet_size, last_file);// go to catch_up function to send previous files
    }
  }
  else{
    ping_result = 0;//set ping to 0 = FAILURE  
    Serial.println("Failure");
    if(last_file == 0){           // no response and this is first failed transmission 
      last_file = file_num;     // save file number that has not been sent
      EEPROM.write(2,last_file);
      EEPROM.write(1,file_num);
    }
  }

}
//--------------------------------------------------
//-----------------------------------------------------------------------------------------
void maintenance_mode(){
  //  Serial.println("IN MAINTENANCE MODE");
  uint8_t maint_mode[] = {  
    0x03                             };// at byte 17 in receive string
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, maint_mode, sizeof(maint_mode));// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
  delay(5000);                      // small delay
  xbee.send(zbTx);                  // after sending a tx request, we expect a status response
}
void setup(){
  Wire.begin();
  pinMode(vdip_rts, OUTPUT);        // set the RTS of VDIP as output
  pinMode(maint_switch, INPUT);     // set maintenace switch as input
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
      file_num = EEPROM.read(1);
      Serial.print("File Number = ");
      Serial.println(file_num);
      last_file = EEPROM.read(2);
      Serial.print("Last file = ");
      Serial.println(last_file);
      int maint_status = digitalRead(maint_switch);
      if (maint_status == LOW){// check if maintenance has been switched on
        maintenance_mode();
      }
      else{
        //--------------------------------------------------Check Oil Switch------------------
        //--------------------------------------------------Call Inverter---------------------
        //--------------------------------------------------Call Time Stamp-------------------
        write_file(file_num, Tx_payload, sizeof(Tx_payload));//-----------------------Write to file---------------------
        Serial.println("Done writing");
        ping_labview(sizeof(Tx_payload));
        Serial.print("Ping result = ");
        Serial.println(ping_result);
        if (ping_result == 1){//ping result = SUCCESS, send data
          send_xbee(Tx_payload, sizeof(Tx_payload), file_num, last_file);//-------------Send Info over Xbee---------------
        }
        if ((file_num > max_file_number) || (file_num > 100 && last_file == 0)){
          delete_files(file_num);// delete files if over limit and all files have been sent
        } 
        else if (file_num > max_file_number && last_file != 0){
          file_num = file_num;// do not increment if over limit and transmission is down
          EEPROM.write(1,file_num);
        } 
        else if (file_num < max_file_number){// increment file number if not over limit
          file_num++; // increment file number for next write
          EEPROM.write(1,file_num);
        }
      }
      Serial.print("File Number = ");
      Serial.println(file_num);
      Serial.print("Last file = ");
      Serial.println(last_file);
    }
  }
}


















