int digiPin = 13;               
int startpoint = .2;
int endpoint = 2;
int runtime = 8640;
int value;
int output = 0;
int increment = 0;

void setup()
{
  pinMode(digiPin, OUTPUT);      // sets the digital pin as output
}

void loop()
{
  digitalWrite(digiPin, HIGH);
  delay(3000);
  digitalWrite(digiPin, value);
  delay(3000);
}



//(((HIGH/2.475)-.2)/8640)
