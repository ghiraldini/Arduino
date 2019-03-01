/*
  SD card datalogger

  Modified from SD - dataLogger Example

  This code read the AIN0 of a thermistor and converts to a temperature
  This temperature is written to an SD card.

  The circuit:
   analog sensors on analog ins 0
   SD card attached to SPI bus as follows:
 ** MOSI - pin 11
 ** MISO - pin 12
 ** CLK - pin 13
 ** CS - pin 4

*/

#include <SPI.h>
#include <SD.h>

const int chipSelect = 4;
const int dioPin = 0;
const int DAY = 86400;

void setup() {
//  pinMode(chipSelect, OUTPUT);
//  digitalWrite(chipSelect, HIGH);
  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.print("Initializing SD card...");

  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  Serial.println("card initialized.");
  pinMode(dioPin, INPUT);    
}

void loop() {
  int count = 0;
  int i = 0;

//  int dioState = digitalRead(dioPin);
//  Serial.print("Digital Read: ");
//  Serial.println(dioState);
  delay(1000);
  
  while (/*dioState == HIGH*/ 1) {
    logH2(count);
    delay(1000);
    i++;
    if (i >= DAY) {
      count++;
      i = 0;
    }
//    dioState = digitalRead(dioPin);
//    if(dioState == LOW){
//      break;
//    }
  }

}


void logH2(int count) {
  // make a string for assembling the data to log:
  String dataString = "";
  // Data File Name Increment
  char dataFileName[] = "Fart_";
  char myFile[32];
  int analogPin = 0;


  sprintf(myFile, "%s%i.txt", dataFileName, count);
  Serial.print("Writing to data file: ");
  Serial.println(myFile);

  int sensor = analogRead(analogPin);
  dataString = String(getH2(sensor));

  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  File dataFile = SD.open(myFile, FILE_WRITE);

  // if the file is available, write to it:
  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
    // print to the serial port too:
    Serial.println(dataString);
  }
  // if the file isn't open, pop up an error:
  else {
    Serial.print("error opening: ");
    Serial.println(dataFileName);
  }

  return;
}

float getH2(int rawADC){
  float h2_val = rawADC * 5.0 / 1024.0;
  return h2_val;
}
