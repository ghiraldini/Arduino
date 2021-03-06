#include <SPI.h>
#include <Ethernet.h>
#include <math.h>
//Schematic:
// [Ground] ---- [10k-Resister] -------|------- [Thermistor] ---- [+5v]
//                                     |
//                                Analog Pin 0
byte mac[] = { 
  0x01, 0xAA, 0x6F, 0x2F, 0xA3, 0xBE };
byte gateway[] = {
  192, 168, 10, 1};
byte subnet[] = {
  255, 255, 255, 0};
IPAddress ip(192,168,10,159);
EthernetServer server(1234);// (port 80 is default for HTTP):

double Thermistor(int RawADC) {
  // Inputs ADC Value from Thermistor and outputs Temperature in Celsius
  //  requires: include <math.h>
  // Utilizes the Steinhart-Hart Thermistor Equation:
  //    Temperature in Kelvin = 1 / {A + B[ln(R)] + C[ln(R)]^3}
  //    where A = 0.001129148, B = 0.000234125 and C = 8.76741E-08
  long Resistance;  
  double Temp;  // Dual-Purpose variable to save space.
  Resistance=((10240000/RawADC) - 10000);  // Assuming a 10k Thermistor.  Calculation is actually: Resistance = (1024 * BalanceResistor/ADC) - BalanceResistor
  Temp = log(Resistance); // Saving the Log(resistance) so not to calculate it 4 times later. // "Temp" means "Temporary" on this line.
  Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));   // Now it means both "Temporary" and "Temperature"
  Temp = Temp - 273.15;  // Convert Kelvin to Celsius                                         // Now it only means "Temperature"

  // BEGIN- Remove these lines for the function not to display anything
  //  Serial.print("ADC: "); Serial.print(RawADC); Serial.print("/1024");  // Print out RAW ADC Number
  //  Serial.print(", Volts: "); printDouble(((RawADC*4.656)/1024.0),3);   // 4.860 volts is what my USB Port outputs.
  //  Serial.print(", Resistance: "); Serial.print(Resistance); Serial.print("ohms");
  // END- Remove these lines for the function not to display anything

  // Uncomment this line for the function to return Fahrenheit instead.
  //Temp = (Temp * 9.0)/ 5.0 + 32.0; // Convert to Fahrenheit
  return Temp;  // Return the Temperature
}


void printDouble(double val, byte precision) {
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimal places
  // example: printDouble(3.1415, 2); // prints 3.14 (two decimal places)
 // Serial.print (int(val));  //prints the int part
  server.print(int(val));
  if( precision > 0) {
    Serial.print("."); // print the decimal point
    unsigned long frac, mult = 1;
    byte padding = precision -1;
    while(precision--) mult *=10;
    if(val >= 0) frac = (val - int(val)) * mult; 
    else frac = (int(val) - val) * mult;
    unsigned long frac1 = frac;
    while(frac1 /= 10) padding--;
    while(padding--) Serial.print("0");
//    Serial.println(frac,DEC);
    server.print(".");
    server.print(frac,DEC);
    server.println(" ");
  }
}


void setup() {
  Serial.begin(9600);
  Ethernet.begin(mac, ip, gateway, subnet);
  Serial.flush();
  server.begin();
}


void loop() {
#define ThermistorPIN 0   // Analog Pin 0
  double temp;
  EthernetClient client = server.available();
  temp=Thermistor(analogRead(ThermistorPIN));           // read ADC and convert it to Celsius
  Serial.print("Celsius: "); 
  printDouble(temp,3);     // display Celsius

  //    temp = (temp * 9.0)/ 5.0 + 32.0;                      // converts to Fahrenheit
  //    Serial.print(", Fahrenheit: "); 
  //    printDouble(temp,3);  // display Fahrenheit

  delay(400);                                           // Delay a bit... for fun, and to not Serial.print faster than the serial connection can output
}


