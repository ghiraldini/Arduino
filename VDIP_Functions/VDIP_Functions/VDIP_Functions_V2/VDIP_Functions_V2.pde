#include "XBee.h" // Library for Xbee Communication
#include "Wire.h" // Library for RTC
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
XBee xbee = XBee();
int flow_out = 52; // CTS of VDIP
int time_date[6]; // array to save time and date
char file_data; // variable to read serial
uint8_t f_data[45]; // array to save data from file
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
byte send_xbee(uint8_t payload[], int fileNumber, int last_file){
  int size = 43;
  XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, 0x402CE5A2);// 64 bit addressing
  Tx64Request tx = Tx64Request(addr64, payload, size);// message packet
  TxStatusResponse txStatus = TxStatusResponse();// transmit response packet
  delay(10000);                     // small delay
  xbee.send(tx);                    // after sending a tx request, we expect a status response
  if (xbee.readPacket(5000)){       // wait up to 5 seconds for the status response
    if (xbee.getResponse().getApiId() == TX_STATUS_RESPONSE){// got a response, should be a znet tx status       
      xbee.getResponse().getZBTxStatusResponse(txStatus);
      if(last_file != 0){           // got a response and previous files have not been sent
        catch_up(fileNumber, last_file);// go to catch_up function to send previous files
      }
    }else if (xbee.getResponse().getApiId() != TX_STATUS_RESPONSE){// did not get response = transmission is down
      if(last_file == 0){           // and this is first failed transmission 
        last_file = fileNumber;     // save file that has not been sent
      }
    }
  }
  delay(1000);
}
byte delete_files(){
  for(int i = 1; i < max_file_number+1; i++){// delete all files starting from fileNumber = 1
  Serial2.print("DLF ");
  Serial2.print(i);
  Serial2.print(".TXT");
  Serial2.print(13, BYTE);
  }
}
byte catch_up(int fileNumber, int last_file){// send all failed transmission files
  while(last_file != fileNumber){   // send from first non sent file to present file
    read_file(last_file);           // read first non sent file
    send_xbee(f_data, fileNumber, last_file);// send file
    last_file++;                    // increment non sent file number
  }
  last_file = 0;                    // set back to zero after catch up is done
}
void setup(){
  Wire.begin();
  pinMode(flow_out, OUTPUT);        // set the CTS of VDIP as output
  xbee.begin(9600);
  Serial.begin(9600);               // start serial
  Serial2.begin(9600);              // start serial#2
  Serial3.begin(9600);              // start serial#3
  Serial2.print("IPA");             // sets the vdip to use ascii numbers 
  Serial2.print(13, BYTE);          // return character to tell vdip its end of message
  Serial.print("Ready");
  Wire.beginTransmission(DS1307_I2C_ADDRESS);        
}
void loop(){
  uint8_t data[] = {"1234567891011121314151617181920"};
  int file_num = 1;
  int last_file = 0;
  if (Serial.available()){
    int incomingByte = Serial.read();
    if (incomingByte == '1'){
      get_date();//---------------------------------Get Time/Date stamp------------
      for(int k = 0; k < 6; k++){
        Serial.print(time_date[k]);
      }
    }
    if (incomingByte == '2'){
      write_file(file_num, data);//---------------------Write to file------------------
    }
    if (incomingByte == '3'){
      read_file(file_num);//-------------------------Read from file------------------
      for(int b = 0; b < 43; b++){
        Serial.print(f_data[b]);
      }
    }
    if (incomingByte == '4'){
      send_xbee(f_data, file_num, last_file);//------Send Info over Xbee---------------
    }
    if (incomingByte == '5'){
      delete_files();//-------------------------------Delete Files----------------------
    }
  }
}
