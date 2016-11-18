#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif 

void setup(){
  cbi(ADMUX, REFS1); //clear REFS1 bit (0)
  cbi(ADMUX, REFS0); //clear REFS0 bit (0)
}

void loop(){
  int weight = analogRead(0);
  if (weight > 0){
    Serial.print(weight);
  }
}


