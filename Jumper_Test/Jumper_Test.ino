//--Jumper pins to change function of box----
int jump1 = 2;
int jump2 = 4;
int mode;

//--Valve Pins----
int valve3 = 13; // be able to use this for 2 valve systems as well
int valve4 = 12;
int valve5 = 11;
int valve6 = 10; 
int valve7 = 9;
int valve8 = 8;

//--Digital Read Values of jumper pins----
int value1;
int value2;

//--Keep track of time passed in function-----
unsigned long time;

//--Test LED pin for debugging----
int ledPin =  3;    

//--Variables for Leak Test and LCD Display
double analogPin = A5;     // Analog pin input
double val = 0;            // variable to store the value read
double wait_time = 30000;
double leak_time = 150000;
double num1 = 0;
double num2 = 0;
double leak = 0;
double volts = 0;
int bits = 0;
int zero = 0; //--variable for sending 0x00 to LCD - error

//------------Initialization-----------------------
void setup()   {                
  Serial.begin(9600);
  Serial.write(12);
  delay(500);
  pinMode(ledPin, OUTPUT);     
  pinMode(valve3, OUTPUT);
  pinMode(valve4, OUTPUT);
  pinMode(valve5, OUTPUT);
  Serial.println("  LGR Test Bench");
  Serial.println("   MultiTasker  ");
  Serial.println("Pressure Testing");
  delay(2000);
  
  //  pinMode(valve6, OUTPUT);
  //  pinMode(valve7, OUTPUT);
  //  pinMode(valve8, OUTPUT);
}

//-------------Main Loop---------------------------
void loop()                     
{
  Serial.begin(9600);
  Serial.write(12);
  pressure_display();
  read_pressure();
  
  //  batch_popper();
  //  LCD_splash();
  //  check_jump();
  //  function_list();
}

//--------------Helper Functions--------------------

void check_jump(){

  value1 = digitalRead(jump1);   
  value2 = digitalRead(jump2);   

  if(value1 == 0 && value2 == 0){
    mode = 1;
  }
  if(value1 == 1 && value2 == 0){
    mode = 2;
  }
  if(value1 == 0 && value2 == 1){
    mode = 3;
  }
  if(value1 == 1 && value2 == 1){
    mode = 4;
  }
}
void function_list(){

  switch(mode){
  case 1:
    popper();    
    break;

  case 2:
    pop_flush();
    break;

  case 3:
    fast_blink();
    break;

  case 4:

    batch_popper();
    break;
  }
}
void popper()                     
{
  digitalWrite(ledPin, HIGH);   
  delay(1500);                  
  digitalWrite(ledPin, LOW);    
  delay(1500);                  
}
void pop_flush()                     
{
  digitalWrite(ledPin, HIGH);   
}
void fast_blink()                     
{
  digitalWrite(ledPin, HIGH);   
  delay(200);                  
  digitalWrite(ledPin, LOW);   
  delay(200);                  
}
void LCD_splash(){
  Serial.begin(9600);
  //Serial.write("ABCDEFGHIJKLMNOPQRSTU");
  Serial.print("    Multi-Tasker    ");
}

void batch_popper(){
  digitalWrite(valve3, HIGH);
  digitalWrite(valve4, HIGH);
  digitalWrite(valve5, HIGH);
  delay(50);
  digitalWrite(valve3, LOW);
  digitalWrite(valve4, LOW);
  digitalWrite(valve5, LOW);
  delay(50);

  /*  digitalWrite(valve6, HIGH);
   digitalWrite(valve7, HIGH);
   digitalWrite(valve8, HIGH);
   digitalWrite(valve9, HIGH);
   digitalWrite(valve0, HIGH);
   digitalWrite(valve3, HIGH);
   */
}


void read_pressure(){
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

void pressure_display(){
  Serial.println("AIN5 Read: ");
  Serial.println("Volt Read: ");
  Serial.println("Leak Rate: ");
  Serial.println("num1 and num2:");
}









