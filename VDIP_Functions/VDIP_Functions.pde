#include "Wire.h"
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
unsigned long dateStamp;
int incomingByte = 0;
int fileNumber = 1;
int noOfChars;
long int valToWrite;
char activityToLog;
long int x;
long int startLogTime = 0;
char data[] = "329876123456789059483636375859606857463738495";
byte file_data;
int i = 0;
int flowOUT = 52; // CTS of VDIP1
//-----------------------------------Convert binary coded decimal to normal decimal numbers------------------------------------------
byte bcdToDec(byte val){
  return ( (val/16*10) + (val%16) );
}
//-----------------------------------Get time and date from RTC DS1307---------------------------------------------------------------
unsigned long dateStampForUSB()  {              // Below required to reset the register address to 0.
  Wire.beginTransmission(DS1307_I2C_ADDRESS);   // transmit to device #104, the ds 1307
  Wire.send(0x00);                              // resets ds1307 to beginning of its registers -could be in setup, 
                                                // but this just makes sure that whenever you are going to do 
                                                // a reading it is starting from the right point
  Wire.endTransmission();                       // stop transmitting

  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);      // request 7 bytes from slave ds1307, we'll assume it'll send them all
                                                // even though it doesn't have to
  int second = bcdToDec(Wire.receive() & 0x7f);     // I have declared all these in here so that the
  int minute = bcdToDec(Wire.receive());        // function is self contained
  int hour = bcdToDec(Wire.receive() & 0x3f);   // you could declare them at the top and then get at
  int day_of_week=bcdToDec(Wire.receive());     // the bits individually elsewhere in the code
  int day = bcdToDec(Wire.receive());           // but this could make the code less logical and
  int month = bcdToDec(Wire.receive());         // more difficult to debugg  
  int year = bcdToDec(Wire.receive());  
  //year = year+20;                               // VDIP starts at 1980, must add 20

  // shift and or values to get one number in format needed for vdip\\
  // doing it in 2 chunks as ints were going wrong if shifted for upper\\
  // values, and didn't want to make all the variables long in case space became an issue\\
  // so create one unsigned long, shift the ints that need to go into the top half into \\
  // the lower half of it, and move them along inside the long var, then or it with the \\
  // lower half values\\

  //unsigned long datecalc=(year<<9)|(month<<5)|(day);
  //unsigned int lsdatecalc=(hour<<11)|(minute<<5)|(second);    
  //datecalc=(datecalc<<16);
  //datecalc=(datecalc)|(lsdatecalc);
  //return datecalc;
  return minute, hour, day_of_week, day, month, year;
} 
//-----------------------------------Flow Setup-----------------------------------------------------------------------
void setup() {
  Wire.begin();
  pinMode(flowOUT, OUTPUT);            // set the CTS of VDIP as output
  Serial.begin(9600);	               // opens serial port, sets data rate to 9600 bps
  Serial3.begin(9600);
  Serial.print("IPA");                 // sets the vdip to use ascii numbers 
                                       // (so I can read them in the code easily!)
  Serial.print(13, BYTE);              // return character to tell vdip its end of message
  Wire.beginTransmission(DS1307_I2C_ADDRESS);        
}
//--------------------------------Serial Monitor Commands--------------------------------------------------------------
void loop() {              
  if (Serial.available()) {            // read the incoming byte
    incomingByte = Serial.read();
    //-----------------------------------------------------------------------------------
      dateStamp=dateStampForUSB();     // gets value for datestamp
      Serial.print(dateStamp);
    if (incomingByte=='1'){            // if it receives a 1
      dateStamp=dateStampForUSB();     // gets value for datestamp
      Serial.print("OPW LOG%");        // open/create file for writing
      Serial.print(fileNumber);        // file number to open/create
      Serial.print(".TXT ");           // make sure there is a space at the end here
      Serial.print("0x");              // tells vdip it is a hex value
      Serial.print(dateStamp, HEX);    // sends datestamp as hex value                   
      Serial.print(13, BYTE);      
      delay(1000);
      Serial.print("WRF ");            // write to file once it is open
      Serial.print(strlen(data));      // tell amount of characters to write
      Serial.print(13, BYTE);
      Serial.println(data);            // write data to file
      Serial.print(13, BYTE);
      delay(1000);
      Serial.print("CLF LOG%");        // close currently open file
      Serial.print(fileNumber);           
      Serial.print(".TXT ");
      Serial.print(13, BYTE);          // return character
      delay(1000);
    }
    //---------------------------------------------------------------------------------------
    if (incomingByte =='2'){
      int i = 0;                       // declare and initialize pointer for reading file
      Serial.print("OPR LOG%");        // open file for reading
      Serial.print(fileNumber);
      Serial.print(".TXT ");           // make sure there is a space at the end here
      Serial.print(13, BYTE);
      delay(1000);
      Serial3.flush();                 // clean out serial buffer
      Serial.print("SEK ");            // set pointer of file to read
      Serial.print(i);
      Serial.print(13, BYTE);
      delay(1000);
      Serial.print(13, BYTE);            
      Serial.print("RDF 45");          // Read from file xx (xx = number of bytes to read)
      Serial.print(13, BYTE);
      delay(1500);
      while (Serial3.available()){     // set loop to read all bytes in buffer
        file_data = Serial3.read();    // read serial buffer
        while (file_data!=68 && file_data!=58 && file_data!=92 && file_data!=62){    // filter out command prompt
          Serial.print(file_data, BYTE); // print bytes saved to variable
          Serial.print(13, BYTE);
          if (file_data == 68)        // break out of loop when command prompt appears again
            Serial3.flush();          // flush buffer and break
          break;      
        }
        digitalWrite(flowOUT, HIGH);  // set CTS high to prepare for closing file
        Serial.print(13, BYTE);
      }
      delay(2000);
      digitalWrite(flowOUT, LOW);     // reset CTS to low to close file
      Serial.print("CLF LOG");        // Close currently open file
      Serial.print(fileNumber);
      Serial.print(".TXT");
      Serial.print(13, BYTE);      
      fileNumber++;                   // increase file number to create new file on next write
    }
  }
}
//---------------------------------THE END-------------------------------------------------------------------------------
