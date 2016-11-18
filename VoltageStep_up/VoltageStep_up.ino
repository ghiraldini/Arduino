int analogPin = 9;
int value = 5;
double t = 1.0;
double x = 1;
double runTime = 0;

void setup(){
  pinMode(analogPin, OUTPUT);
}
// Step voltage from 0.1V - 2.0V in 8 steps
void loop(){
  analogWrite(analogPin, value);z
  delay(60000);
  while(value < 90){  
    analogWrite(analogPin, value);
    delay(300000);
    value+=10;
  }
  value = 1;
  analogWrite(analogPin, value);
  delay(360000);
}








