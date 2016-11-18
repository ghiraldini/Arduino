
double analogPin = A5;     // Analog pin input
double val = 0;           // variable to store the value read
double wait_time = 30000;
double leak_time = 150000;
double time = 0;
double num1 = 0;
double num2 = 0;
double leak = 0;
double volts = 0;
int bits = 0;



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
  pressuretest();
  read_display();
}

void pressuretest(){
  Serial.println("AIN5 Read: ");
  Serial.println("Volt Read: ");
  Serial.println("Leak Rate: ");
  Serial.println("num1 and num2:");
}

void read_display(){
  time = millis();
  while(1){
    byte zero = 0;
    Serial.write(17);
    Serial.write(11);
    Serial.write(zero);  
    bits = analogRead(analogPin);
    Serial.println(bits);

    Serial.write(17);
    Serial.write(11);
    Serial.write(1);  
    volts = bits/204.800;
    Serial.println(volts);

    Serial.write(17);
    Serial.write(zero);
    Serial.write(3);  

    if(time == wait_time){
      num1 = volts;
    }
    if(time == leak_time){
      num2 = volts;
    }

    if(time > leak_time){

      leak = num2-num1/leak_time;

      Serial.write(17);
      Serial.write(11);
      Serial.write(2);  
      Serial.println(leak);

      Serial.write(17);
      Serial.write(14);
      Serial.write(3);  
      Serial.println(num1);

    }
    delay(250);  
  }
}




