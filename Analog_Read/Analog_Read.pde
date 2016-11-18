
double analogPin = A0;     // Analog pin input
double val = 0;           // variable to store the value read
double leak = 0;
void setup()
{
  Serial.begin(9600);          //  setup serial
  Serial.write(12);
//Serial.println("ABCDEFGHIJKLMNOPQRST"); // 19 Chars to fill 1 line
  Serial.println("Hannah's Test Bench");
  Serial.println("     (LGR INC)     ");
  Serial.println(" Pressure Testing ");
  delay(5000);
  Serial.write(31);
  delay(3000);

}

void loop()
{
  Serial.begin(9600);
  Serial.write(12);
  val += analogRead(analogPin);
  leak = val/millis();
  Serial.print("A0 Read: ");
  Serial.println(analogRead(analogPin));
  Serial.print("Volt Read: ");
  Serial.println(analogRead(analogPin)/204.80);
  Serial.print("Leak Rate: ");
  Serial.println(leak);
  delay(500);
}

//  Serial.write(17);
//  Serial.write(10);
//  Serial.write(0);  

