int flow_out = 52; // CTS of VDIP
int file = 1;
//------------------------------------------------------Test VDIP FIle Storage Size-----------------------
long int write_file(int fileNumber, uint8_t data[]){
  delay(1000);
  Serial2.print("OPW ");            // open/create file for writing
  Serial2.print(fileNumber);        // file number to open/create
  Serial2.print(".TXT ");           // make sure there is a space at the end here
  Serial2.print(13, BYTE);      
  delay(1000);
  Serial2.print("WRF 11");            // write to file once it is open
  Serial2.print(13, BYTE);
  for(int i = 0; i<11; i++){
    Serial2.print(data[i], BYTE);              // write data to file
    delay(500);
  }
  Serial2.print(13, BYTE);
  delay(1000);
  Serial2.print("CLF ");            // close currently open file
  Serial2.print(fileNumber);           
  Serial2.print(".TXT ");
  Serial2.print(13, BYTE);          // return character
  delay(1000);
}  

void setup(){
  pinMode(flow_out, OUTPUT);         // set the CTS of VDIP as output
  Serial.begin(9600);                // start serial
  Serial2.begin(9600);               // start serial#2
  Serial3.begin(9600);               // start serial#3
  Serial2.print("IPA");              // sets the vdip to use ascii numbers 
  Serial2.print(13, BYTE);           // return character to tell vdip its end of message
  Serial.println("Ready");
}
void loop(){
  uint8_t j[] = {"12345678910"};  
  if (Serial.available() > 0){
    int incomingByte = Serial.read();
    if (incomingByte=='1'){
      for (int i = 1; i < 701; i++){  
        Serial.println(i);
        write_file(file, j);
        file++;
        delay(500);
      }
    }
  }
}


