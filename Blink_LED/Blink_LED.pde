// Blinks LED on and off at one second intervals

int ledPin =  7;    // LED connected to digital pin 13
double time = 0;
// The setup() method runs once, when the sketch starts

void setup()   {                
  pinMode(ledPin, OUTPUT);     
}
void loop()                    
{
  time = millis();
  popper();
  pop_flush();
  wait();
}


void popper(){

  while(time < 30000){
    digitalWrite(ledPin, HIGH);   
    delay(1500);                  
    digitalWrite(ledPin, LOW);    
    delay(1500);                  
  }

}

void pop_flush(){
   while(time < 150000){
    digitalWrite(ledPin, HIGH);
   } 
}

void wait(){
  while(1){
    digitalWrite(ledPin, HIGH);   
    delay(700);                  
    digitalWrite(ledPin, LOW);    
    delay(700);                  
  }
}
