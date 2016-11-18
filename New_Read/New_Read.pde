#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#include "EEPROM.h"
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
XBeeResponse response = XBeeResponse(); // declare response
ZBRxResponse rx = ZBRxResponse(); // declare response
int file_num = 1; // initalize file numbering
int last_file = 0; // global last sent transmission
int in_catch_up_mode; // flag to show in catch_up
int flow_out = 52; // RTS of VDIP
int time_date[5]; // array to save time and date
byte file_data[100]; // variable to read serial
uint8_t f_data[33]; // array to save data from file
int max_file_number = 485; // when fileNumber = max_file_number go to delete_files
int start_up = 40;
uint8_t data[] = {
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x44, 0x7, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0xA0}; // dummy info
int packet_size = sizeof(data);
byte input;

void setup(){
  Wire.begin();
  pinMode(flow_out, OUTPUT);        // set the RTS of VDIP as output
  pinMode(start_up, INPUT);
  xbee.begin(9600);                 // start xbee
  Serial.begin(9600);               // start serial - for debugging
  Serial2.begin(9600);              // start serial#2 - for VDIP1
  Serial3.begin(9600);              // start serial#3 - for Xbee
  Serial2.print("IPA");             // sets the vdip to use ascii numbers 
  Serial2.print(13, BYTE);          // return character to tell vdip its end of message
  Serial.println("Ready");
  int val = digitalRead(start_up);
  if (val == LOW){
    file_num = EEPROM.read(1);
    delete_files(file_num);
    EEPROM.write(1,1);
    EEPROM.write(1,0);
  }
  else{
    file_num = EEPROM.read(1);
    last_file = EEPROM.read(2);
  }
}

void loop(){
  if(Serial.available()){
    int incomingByte = Serial.read();// start execution through serial monitor for testing purposes
    if (incomingByte == '1'){ // send "1" to start loop
      Serial.print("Packet Size: ");
      Serial.println(packet_size);
      write_file(file_num, data, packet_size);//--------------Write to file-------------
      delay(1000);
      read_file(file_num, packet_size);
      delay(1000);
      Serial.print("VDIP Data After Read: ");
      for (int i = 0; i < packet_size; i++){
        Serial.print(f_data[i], HEX);
      }
      Serial.println();
      //      send_xbee(f_data, file_num, last_file);//-------------Send Info over Xbee-------

      if (file_num > max_file_number && last_file == 0){
        delete_files(file_num);// delete files if over limit and all files have been sent
      } 
      else if (file_num > max_file_number && last_file != 0){
        file_num = file_num;// do not increment if over limit and transmission is down
      } 
      else if (file_num < max_file_number){// increment file number if not over limit
        file_num++; // increment file number for next write
      }
    }
  }
}

void write_file(int fileNumber, uint8_t payload[], int packet_size){
  Serial.print("Writing to file: ");
  Serial.println(fileNumber);
  if (fileNumber > max_file_number){
    return;
  }
  delay(500);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(fileNumber);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(500);
  Serial2.print("WRF ");          // write to file once it is open (number = bits to write)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  for(int i = 0; i < packet_size; i++){
    Serial2.write(payload[i]);         // write data to file
    delay(50);
  }
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(fileNumber);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  delay(1000);
}  
int read_file(int fileNumber, int packet_size){
  Serial.print("Reading File: ");
  Serial.println(fileNumber);
  byte input;
  int i = 0;                        // declare and initialize pointer for reading file
  unsigned long timer = 0;
  unsigned long time_limit = 30000;
  delay(500);
  Serial2.print("OPR ");            // open file for reading
  Serial2.print(fileNumber);
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.flush();                  // clean out serial buffer
  Serial2.print("SEK ");            // set pointer of file to read
  Serial2.print(i);
  Serial2.print(13, BYTE);
  delay(500);
  Serial2.print(13, BYTE);            
  Serial.flush();
  Serial2.print("RDF ");           // Read from file xx (xx = number of bytes to read)
  Serial2.print(packet_size);
  Serial2.print(13, BYTE);
  delay(500);
  //---------------------------------------new test read
  Serial.println("Reading Serial");
  while(Serial2.available()){
//    while(input != 0x44){
      file_data[i] = Serial2.read();
      Serial.print(file_data[i], HEX);
      i++;
      
//    }
  }
    
  digitalWrite(flow_out, HIGH);   // set RTS high to prepare for closing file
  Serial2.print(13, BYTE);
  delay(2000);
  digitalWrite(flow_out, LOW);      // reset RTS to low to close file
  //-------------------------------------------end of new test read
  /*
  Serial.print("Serial Input from VDIP: ");
   while (Serial2.available()){      // set loop to read all bytes in buffer
   file_data[i] = Serial2.read();     // read serial buffer
   i++;
   Serial.print(file_data[i], HEX);
   }
   digitalWrite(flow_out, HIGH);   // set RTS high to prepare for closing file
   Serial2.print(13, BYTE);
   delay(2000);
   digitalWrite(flow_out, LOW);      // reset RTS to low to close file
   */
  Serial2.print("CLF ");            // Close currently open file
  Serial2.print(fileNumber);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);      
  delay(500);
  delay(1000);
/*  Serial.print("Data read: ");
  for(int j = 0; j<55; j++){
    Serial.print(file_data[j], HEX);
  }*/
  Serial.println();
  Serial.print("F_Data: ");
   int j = 10;
   for (int k = 0; k < 33; k++){
   f_data[k] = file_data[j];
   j++;
   Serial.print(f_data[k], HEX);
   }
   
   Serial.println();
   /*
   Serial.print("Byte 1: ");
   Serial.println(file_data[0], HEX);
   Serial.print("Byte 2: ");
   Serial.println(file_data[1], HEX);
   Serial.print("Byte 3: ");
   Serial.println(file_data[2], HEX);
   Serial.print("Byte 4: ");
   Serial.println(file_data[3], HEX);
   Serial.print("Byte 5: ");
   Serial.println(file_data[4], HEX);
   Serial.print("Byte 6: ");
   Serial.println(file_data[5], HEX);
   */
}

void delete_files(int file_number1){
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
    Serial.print("File Number: ");
    Serial.print(file_num);
    Serial.print(", Last File: ");
    Serial.println(last_file);
  } 
}


