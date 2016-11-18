int ledPin =  7;   
unsigned long time = 0;
unsigned long pop_time = 600000; // 10 min
unsigned long flush_time = 1200000; // another 10 min

void setup()   {                
  pinMode(ledPin, OUTPUT);     
}
void loop()                    
{
  popper();
  pop_flush();
  wait();
}


void popper(){

  while(time < pop_time){
    time = millis();
    digitalWrite(ledPin, HIGH);   
    delay(1500);                  
    digitalWrite(ledPin, LOW);    
    delay(1500);                  
  }

}

void pop_flush(){
  while(time < flush_time){
    time = millis();
    digitalWrite(ledPin, HIGH);
  } 
}

void wait(){
  while(1){
    digitalWrite(ledPin, HIGH);   
    delay(200);                  
    digitalWrite(ledPin, LOW);    
    delay(100);                  
  }
}

