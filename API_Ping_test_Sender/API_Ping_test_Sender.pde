// Test of API Ping string
// This test is designed to send a predefined string of bytes that correspond to a properly
// formatted Tx request packet from a 900MHz XBee radio configured with XCTU as follows:
// ID: 7FFF   (This is the Network ID parameter)  - Yours may be different
// AP: 2      (API mode with escaped codes)
// DH & DL: Set per radios in use for test    
// ----------------------------------------------------------------------------- test variables
byte ping[] = { 0x7E, 0x00, 0x7D, 0x31, 0x10, 0x01, 0x00, 0x7D, 0x33, 0xA2, 0x00, 0x40, 0x3A, 0x34, 0xAC, 0x7F, 0xFF, 0x00, 0x00, 0x02, 0x4F, 0x4B, 0xC5 }; 
// Note bytes 6-14 (counting from 1, left to right)  are based on my destination address of DH = 0x0013A200, DL = 0x40547B54. 
// Change these values to match your radios;
// Change bytes 15&16 to match your radio network ID, these are referred to as reserved in the spreadsheet I sent previously
// The checksum must be recalculated to reflect these changes.
// See the spreadsheet I sent previously and the Digi manual: XBee-PRO® 900/DigiMesh™ 900 OEM RF Modules
// ------------------------------------------------------------------
void setup(){
    Serial3.begin(9600);              // start serial#3 for Xbee, change to Serial.begin(9600) if not using MEGA
    Serial.begin(9600);
}
void loop(){
  writeHexArray( ping, sizeof(ping));
exit(1);
}
// ---------------------------------------------------------------- functions
// Helper function to write hex array to serial port
// requires array name and size of array to be passed as parameters
void writeHexArray(byte *array, int count) {           // Helper function to print an array to the serial port
Serial.println("In Function");
  while (count--) 
    Serial3.write(*array++);                           // Change to Serial.write() if not using MEGA
    Serial.println("writing to serial 3");
}
