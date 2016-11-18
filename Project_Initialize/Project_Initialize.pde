#include "EEPROM.h"

int file_num = 1;
int last_file = 0;

void setup(){
  Serial.begin(9600);
}

void loop(){
  EEPROM.write(1,file_num);
  EEPROM.write(2,last_file);
}
