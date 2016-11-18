#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#include "EEPROM.h" // Library to save pointers/variables
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
XBeeResponse response = XBeeResponse(); // declare response
ZBRxResponse rx = ZBRxResponse(); // declare response
int file_num = 1; // initalize file numbering
int last_file; // global last sent transmission
int in_catch_up_mode; // flag to show in catch_up
int vdip_rts = 52; // RTS of VDIP connected to pin 36
int time_date[5]; // array to save time and date
char file_data;
int max_file_number = 485; // when fileNumber = max_file_number go to delete_files
uint8_t Tx_payload[] = { 
  0x01, 0x02, 0x03, 0x04, 0x05, 0x68, 0x01, 0x02, 0x03, 0x04, 0x05, 0x58, 0x01, 0x02, 0x03, 0x04, 0x05, 0x92, 0x01, 0x02, 0x03, 0x04, 0x05, 0x62, 0x01, 0x02, 0x03, 0x04, 0x05, 0x68, 0x99}; // dummy info
//--------------------------------------------Bill's variable for Packet - delete when merging code
uint8_t f_data[32]; // array to save data from file
byte data_in[20];// length of received string from labview ping response
int ping_result;// status from labview ping
int maint_switch = 50;// maintenance switch connected to digital pin 40
//-----------------------------------------------------------------------------------------------------------------------
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
void maintenance_mode(){
  //  Serial.println("IN MAINTENANCE MODE");
  uint8_t maint_mode[] = {   
    0x03     };// byte 17 in receive string
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x403A34AC);// 64 bit addressing (900MHz Radios)
  ZBTxRequest zbTx = ZBTxRequest(addr64, maint_mode, sizeof(maint_mode));// message packet
  ZBTxStatusResponse txStatus = ZBTxStatusResponse();// transmit response packet
  delay(5000);                      // small delay
  xbee.send(zbTx);                  // after sending a tx request, we expect a status response
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
      //      file_num = EEPROM.read(1);
      //      last_file = EEPROM.read(2);
      int maint_status = digitalRead(maint_switch);
      if (maint_status == HIGH){// check if maintenance has been switched on
        maintenance_mode();
      }
      //--------------------------------------------------Check Oil Switch------------------
      //--------------------------------------------------Call Inverter---------------------
      //--------------------------------------------------Call Time Stamp-------------------
      //write_file(file_num, Tx_payload, sizeof(Tx_payload));//-----------------------Write to file---------------------
      //delay(2000);
      //read_file(file_num, sizeof(Tx_payload));
      //ping_labview(sizeof(Tx_payload));
      //send_xbee(f_data, sizeof(Tx_payload), file_num, last_file);//-------------Send Info over Xbee---------------
    }
  }
}





