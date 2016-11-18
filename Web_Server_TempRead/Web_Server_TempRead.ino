#include <SPI.h>
#include <Ethernet.h>

byte mac[] = { 0xEE, 0xAE, 0xBC, 0xEB, 0xFE, 0xED };
IPAddress ip(10,0,0,5);// The IP address will be dependent on your local network:

EthernetServer server(80);// (port 80 is default for HTTP):

void setup() {
  Serial.begin(9600);
   while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  Ethernet.begin(mac, ip);  // start the Ethernet connection and the server:
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}


void loop() {
  // listen for incoming clients
  EthernetClient client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println("Connection: close");  // the connection will be closed after completion of the response
	        client.println("Refresh: 1");  // refresh the page automatically every 5 sec
          client.println();
          client.println("<!DOCTYPE HTML>");
          client.println("<html>");
          // output the value of each analog input pin
          for (int analogChannel = 0; analogChannel < 1; analogChannel++) {
            int sensorReading = analogRead(analogChannel);
            long Resistance;  
            double Temp;  // Dual-Purpose variable to save space.
            Resistance=((10240000/sensorReading) - 10000);  // Assuming a 10k Thermistor.  Calculation is actually: Resistance = (1024 * BalanceResistor/ADC) - BalanceResistor
            Temp = log(Resistance); // Saving the Log(resistance) so not to calculate it 4 times later. // "Temp" means "Temporary" on this line.
            Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));   // Now it means both "Temporary" and "Temperature"
            Temp = Temp - 273.15;  // Convert Kelvin to Celsius                                         // Now it only means "Temperature"

            client.print("analog input ");
            client.print(analogChannel);
            client.print(" is ");
            client.print(Temp);
            client.println("<br />");       
          }
          client.println("</html>");
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("client disonnected");
  }
}
