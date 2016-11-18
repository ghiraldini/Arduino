int analogPin = 9;
double AINPin = 0;
double Vin = 0;
int value = 21;
double time = 180000.0;

void setup(){
  pinMode(analogPin, OUTPUT);
  pinMode(AINPin, INPUT);
  Serial.begin(9600);
  Serial.println("Starting...");
}

void loop(){
  while(value < 221){
  analogWrite(analogPin, value);
  Vin = analogRead(AINPin);
  double voltageIN = (Vin/1023)*5;
  Serial.print("Voltage Out: ");
  Serial.println(value);
  Serial.print("Voltage In: ");
  Serial.println(voltageIN);
  value+=21;
  delay(time);
  }
}








