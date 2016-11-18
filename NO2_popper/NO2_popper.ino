// Blinks LED on and off at one second intervals

int highFlowPin =  12;    
int ThreeWayValve = 11;
int pops = 0;
int totalpops = 20;
int ledState = LOW;   
unsigned long time = 0;

void setup()   {                
  Serial.begin(9600);
  pinMode(highFlowPin, OUTPUT);     
  pinMode(ThreeWayValve, OUTPUT);
}
void loop()                    
{
  popper();
  toggle();
  // pop_flush();
}


void popper(){
  while(pops < totalpops){
    Serial.println(pops);
    digitalWrite(highFlowPin, HIGH);   
    delay(1500);                  
    digitalWrite(highFlowPin, LOW);    
    delay(1500);
    pops++;    
  }
  pops = 0;
}

void toggle(){
  if (ledState == LOW)
    ledState = HIGH;
  else
    ledState = LOW;
  digitalWrite(ThreeWayValve, ledState);
}

void pop_flush(){
  while(time < 150000){
    digitalWrite(highFlowPin, HIGH);
  } 
}




