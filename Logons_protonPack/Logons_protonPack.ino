// Blinks LED on and off at one second intervals

int ledPin0 = 2;    // LED connected to digital pin 2 - always on

int ledPin1 = 4;    // rotating LEDS
int ledPin2 = 5;
int ledPin3 = 6;
int ledPin4 = 7;

// The setup() method runs once, when the sketch starts

void setup()   {                
  pinMode(ledPin0, OUTPUT);     
  
  pinMode(ledPin1, OUTPUT);     
  pinMode(ledPin2, OUTPUT);     
  pinMode(ledPin3, OUTPUT);     
  pinMode(ledPin4, OUTPUT);     
}

void loop()                    
{
  digitalWrite(ledPin0, HIGH);
  
  digitalWrite(ledPin1, HIGH);   
  delay(800);                  
  digitalWrite(ledPin1, LOW);    
  
  digitalWrite(ledPin2, HIGH);   
  delay(800);                  
  digitalWrite(ledPin2, LOW);    

  digitalWrite(ledPin3, HIGH);   
  delay(800);                  
  digitalWrite(ledPin3, LOW);    

  digitalWrite(ledPin4, HIGH);   
  delay(800);                  
  digitalWrite(ledPin4, LOW);    

}

