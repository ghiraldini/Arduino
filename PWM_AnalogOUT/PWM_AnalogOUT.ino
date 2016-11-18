int digitalPin1 = 10;
int digitalPin2 = 11;
int digitalPin3 = 12;
int analogPin = 9;
int value = 221;
double t = 1.0;
double x = 1;
double runTime = 0;

void setup(){
  pinMode(analogPin, OUTPUT);
  pinMode(digitalPin1, OUTPUT);
  pinMode(digitalPin2, OUTPUT);
  pinMode(digitalPin3, OUTPUT);
}

void loop(){
  while(millis() < 50000){
    analogWrite(analogPin, 255);

    while(millis() < 25000){
      digitalWrite(digitalPin1, HIGH);
    }
    while(millis() < 28000){
      digitalWrite(digitalPin2, HIGH);
    }
    while(millis() < 40000){
      digitalWrite(digitalPin3, HIGH);
    }
  }
  while(value > 20){
    while(value > 119){
      analogWrite(analogPin, value);
      delay(35000);
      value-=20;
    }
    analogWrite(analogPin, value);
    value-=3;
    t = .05*x*x+17;
    t = t*1000;
    x+=1;
    delay(t);
  }
  analogWrite(analogPin, value);
  delay(10000);
  value = 200;
  analogWrite(analogPin, 255);
  digitalWrite(digitalPin1, HIGH);
  delay(30000);
  digitalWrite(digitalPin1, LOW);
  digitalWrite(digitalPin2, LOW);
  digitalWrite(digitalPin3, LOW);
}







