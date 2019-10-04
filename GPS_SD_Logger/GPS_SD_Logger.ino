#include <Adafruit_GPS.h>
#include <SoftwareSerial.h>

#include <SPI.h>
#include <SD.h>

/*
  SD card datalogger

  This example shows how to log data from three analog sensors
  to an SD card using the SD library.

  The circuit:
   SD card attached to SPI bus as follows:
 ** MOSI - pin 11
 ** MISO - pin 12
 ** CLK - pin 13
 ** CS - pin 4 (for MKRZero SD: SDCARD_SS_PIN)
*/

// GPS NOTES
// Connect the GPS Power pin to 5V
// Connect the GPS Ground pin to ground
// If using software serial (sketch example default):
//   Connect the GPS TX (transmit) pin to Digital 8
//   Connect the GPS RX (receive) pin to Digital 7
// If using hardware serial:
//   Connect the GPS TX (transmit) pin to Arduino RX1 (Digital 0)
//   Connect the GPS RX (receive) pin to matching TX1 (Digital 1)

// If using software serial, keep these lines enabled
// (you can change the pin numbers to match your wiring):
SoftwareSerial mySerial(8, 7);
Adafruit_GPS GPS(&mySerial);

// If using hardware serial, comment
// out the above two lines and enable these two lines instead:
//Adafruit_GPS GPS(&Serial1);
//HardwareSerial mySerial = Serial1;

// Set GPSECHO to 'false' to turn off echoing the GPS data to the Serial console
// Set to 'true' if you want to debug and listen to the raw GPS sentences
#define GPSECHO  true

// Set true to parse GPS Data and Print
#define PARSE true

// Set true to only read RAW GPS Sentences
#define RAW true

String gps_str = "";
String raw_str = "";
const int GPS_LOCK_LED = 12;

const int chipSelect = 4;

void setup()
{

  // connect at 115200 so we can read the GPS fast enough and echo without dropping chars
  // also spit it out
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.print("Initializing SD card...");

  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    while (1);
  }
  Serial.println("card initialized.");

  // 9600 NMEA is the default baud rate for Adafruit MTK GPS's- some use 4800
  GPS.begin(9600);
  Serial.print("Initializing GPS...");
  
  // uncomment this line to turn on RMC (recommended minimum) and GGA (fix data) including altitude
  // GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
  // uncomment this line to turn on only the "minimum recommended" data
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCONLY);

  // Set the update rate
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);   // 1 Hz update rate
  // For the parsing code to work nicely and have time to sort thru the data, and
  // print it out we don't suggest using anything higher than 1 Hz

  // Request updates on antenna status, comment out to keep quiet
  //  GPS.sendCommand(PGCMD_ANTENNA);

  delay(1000);
  // Ask for firmware version
  mySerial.println(PMTK_Q_RELEASE);

  pinMode(GPS_LOCK_LED, OUTPUT);  
  digitalWrite(GPS_LOCK_LED, LOW);
}



void log_gps(String gps_str) {
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  File dataFile = SD.open("datalog.txt", FILE_WRITE);

  // if the file is available, write to it:
  if (dataFile) {
    dataFile.println(gps_str);
    dataFile.close();
    // print to the serial port too:
    Serial.println(gps_str);
  }
  // if the file isn't open, pop up an error:
  else {
    Serial.println("error opening datalog.txt");
  }
}


uint32_t timer = millis();

void loop()                     
{

  

  log_gps("-----------------------------------------------------");
  log_gps("\t\tSTART OF NEW DATA");
  log_gps("-----------------------------------------------------");
  
  while (true) {
    raw_str = GPS.read();

    // Aggregated full GPS Sentence and ready to display
    if (raw_str.equals("$")) {

      // log to SD card
      log_gps(gps_str);

      // Clear string buffer
      gps_str = "";

    } else {

      // continue to add string to buffer
      gps_str += raw_str;

    }

    // if millis() or timer wraps around, we'll just reset it
    if (timer > millis())  timer = millis();

    // For parsing data, we don't suggest using anything but either RMC only or RMC+GGA since
    // the parser doesn't care about other sentences at this time
    if (PARSE) {
      // approximately every 1 second or so, print out the current stats
      if (millis() - timer > 1000) {
        timer = millis(); // reset the timer

        Serial.print("\nTime: ");
        Serial.print(GPS.hour, DEC); Serial.print(':');
        Serial.print(GPS.minute, DEC); Serial.print(':');
        Serial.print(GPS.seconds, DEC); Serial.print('.');
        Serial.println(GPS.milliseconds);
        Serial.print("Date: ");
        Serial.print(GPS.day, DEC); Serial.print('/');
        Serial.print(GPS.month, DEC); Serial.print("/20");
        Serial.println(GPS.year, DEC);
        Serial.print("Fix: "); Serial.print((int)GPS.fix);
        Serial.print(" quality: "); Serial.println((int)GPS.fixquality);
        
        if (GPS.fix) {
          digitalWrite(GPS_LOCK_LED, HIGH);
          
          Serial.print("Location: ");
          Serial.print(GPS.latitude, 4); 
          Serial.print(GPS.lat);
          Serial.print(", ");
          Serial.print(GPS.longitude, 4); 
          Serial.println(GPS.lon);
        
          gps_str = String(GPS.latitude) + ", " + String(GPS.longitude);
          log_gps(gps_str);
            
          Serial.print("Speed (knots): "); Serial.println(GPS.speed);
          Serial.print("Angle: "); Serial.println(GPS.angle);
          Serial.print("Altitude: "); Serial.println(GPS.altitude);
          Serial.print("Satellites: "); Serial.println((int)GPS.satellites);
        } else {
          // set LED LOW
          digitalWrite(GPS_LOCK_LED, LOW);
        }
      }
    }
  }
}
