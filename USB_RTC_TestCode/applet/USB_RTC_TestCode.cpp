#include "Wire.h"
#define DS1307_I2C_ADDRESS 0x68  // This is the I2C address
#include "WProgram.h"
byte bcdToDec(byte val);
unsigned long dateStampForUSB();
void setup();
void loop();
unsigned long dateStamp;
int incomingByte=0;
int fileNumber=1;
int noOfChars;
long int valToWrite;
char activityToLog;
long int x;
long int startLogTime = 0;
char data[] = "Load Current = 7 Amps"
"Gen_Satus = Off"
"Solar Voltage = 45 Volts"
"End";
int time = 0;
int start = 1;
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
  int second = bcdToDec(Wire.receive() & 0x7f); // I have declared all these in here so that the
  int minute = bcdToDec(Wire.receive());        // function is self contained
  int hour = bcdToDec(Wire.receive() & 0x3f);   // you could declare them at the top and then get at
  int day_of_week=bcdToDec(Wire.receive());     // the bits individually elsewhere in the code
  int day = bcdToDec(Wire.receive());           // but this could make the code less logical and
  int month = bcdToDec(Wire.receive());         // more difficult to debugg  
  int year = bcdToDec(Wire.receive());  
  year = year+20;                               // VDIP starts at 1980, must add 20

   // shift and or values to get one number in format needed for vdip\\
   // doing it in 2 chunks as ints were going wrong if shifted for upper\\
   // values, and didn't want to make all the variables long in case space became an issue\\
   // so create one unsigned long, shift the ints that need to go into the top half into \\
   // the lower half of it, and move them along inside the long var, then or it with the \\
   // lower half values\\

  unsigned long datecalc=(year<<9)|(month<<5)|(day);
  unsigned int lsdatecalc=(hour<<11)|(minute<<5)|(second);    
  datecalc=(datecalc<<16);
  datecalc=(datecalc)|(lsdatecalc);
  return datecalc;
} 
//-----------------------------------Flow Setup-----------------------------------------------------------------------
void setup() {
  Wire.begin();
  Serial.begin(9600);	                   // opens serial port, sets data rate to 9600 bps
  Serial3.begin(9600);                     // opens another serial port 
  Serial2.begin(9600);
  Serial.print("IPA");                     // sets the vdip to use ascii numbers 
                                           // (so I can read them in the code easily!)
  Serial.print(13, BYTE);                  // return character to tell vdip its end of message
  Wire.beginTransmission(DS1307_I2C_ADDRESS);        
}
//--------------------------------Send Data and Time/Date in loop--------------------------------------------------------------
void loop() {
  //int start = 1;
  if (Serial3.available()){
    incomingByte = Serial3.read();
    if (incomingByte = '1'){
      while (start = 1){
      for(int i = 1; i < 41; i++)
      char TMP = Serial2.read();
    dateStamp=dateStampForUSB();        // gets value for datestamp
    Serial.print("OPW LOG%");
    Serial.print(fileNumber);
    Serial.print(".TXT ");             // make sure there is a space at the end here
    Serial.print("0x");                // tells vdip it is a hex value
    Serial.print(dateStamp, HEX);      // sends datestamp as hex value                   
    Serial.print(13, BYTE);      
    delay(1000);
    for(int j = 1; j < 4; j++){
    Serial.print("WRF ");              // Write to file once it is open
    Serial.print(strlen(data));        // Tell amount of characters to write
    Serial.print(13, BYTE);
    Serial.println(data);                // Write data to file
    Serial.print(13, BYTE);
    }
    delay(1000);
    Serial.print("CLF LOG%");          // it closes the file
    Serial.print(fileNumber);          // LOG%1.TXT
    Serial.print(".TXT");
    Serial.print(13, BYTE);            // return character
    fileNumber++;                      // increment fileNumber for next file name
    time++;
    delay(1000);
    for(int i = 1; i < 41; i++){
    Serial3.print(strlen(data));
    Serial3.print(13,BYTE);
    Serial3.print(data);
    Serial3.print(13,BYTE);
    }

    
  if (Serial3.available()){  
    incomingByte = Serial3.read();
  if (incomingByte == '2'){
    exit(0);
    
  }
    }
            delay(900000);
    }
}
}
}
//---------------------------------THE END-------------------------------------------------------------------------------


int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

