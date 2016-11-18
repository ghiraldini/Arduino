int digpin2 = 2;
int digpin3 = 3;
int digpin4 = 4;
int digpin5 = 5;
int digpin6 = 6;
int digpin7 = 7;
int digpin8 = 8;
int digpin9 = 9;
int digpin10 = 10;
int digpin11 = 11;
int digpin12 = 12;

void setup() {
  Serial.begin(9600);
  // 11 digital control lines
  pinMode(digpin2, OUTPUT);
  pinMode(digpin3, OUTPUT);  
  pinMode(digpin4, OUTPUT);
  pinMode(digpin5, OUTPUT);
  pinMode(digpin6, OUTPUT);  
  pinMode(digpin7, OUTPUT);
  pinMode(digpin8, OUTPUT);
  pinMode(digpin9, OUTPUT);  
  pinMode(digpin10, OUTPUT);
  pinMode(digpin11, OUTPUT);
  pinMode(digpin12, OUTPUT); 
 // 5 analog control lines 
  pinMode(A0, OUTPUT); 
  pinMode(A1, OUTPUT);  
  pinMode(A2, OUTPUT);     
  pinMode(A3, OUTPUT);
  pinMode(A4, OUTPUT); 
// 1 Signal Control line - reserved
  pinMode(A5, OUTPUT); // Control Signal for DPG/WVISS
}

void loop() {
  while (Serial.available()) {
    char inByte = Serial.read();     
    switch (inByte){

    case 48: // case #1 Number 0
      digitalWrite(digpin2, HIGH);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 49: // case #2
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, HIGH);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);   
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 50: // case #3
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, HIGH);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 51: // case #4
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, HIGH);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 52: // case #5
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, HIGH);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 53: // case #6
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, HIGH);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 54: // case #7
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, HIGH);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);   
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 55: // case #8
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, HIGH);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);    
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 56: // case #9
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, HIGH);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);    
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;

    case 57: // case #10 
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, HIGH);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;

    case 65: // case #11 Letter A
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, HIGH);   
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 66: // case #12 Letter B  
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, HIGH);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 67: // case #13 Letter C
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, HIGH);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 68: // case #14 Letter D  
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, HIGH);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    case 69: // case #15 Letter E  
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, HIGH);
      digitalWrite(A4, LOW);
      break;
    case 70: // case #16 Letter F  
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);  
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, HIGH);
      break;
    default:
      digitalWrite(digpin2, LOW);  
      digitalWrite(digpin3, LOW);  
      digitalWrite(digpin4, LOW);  
      digitalWrite(digpin5, LOW);  
      digitalWrite(digpin6, LOW);  
      digitalWrite(digpin7, LOW);  
      digitalWrite(digpin8, LOW);  
      digitalWrite(digpin9, LOW);  
      digitalWrite(digpin10, LOW);  
      digitalWrite(digpin11, LOW);  
      digitalWrite(digpin12, LOW);    
      digitalWrite(A0, LOW);
      digitalWrite(A1, LOW);
      digitalWrite(A2, LOW);
      digitalWrite(A3, LOW);
      digitalWrite(A4, LOW);
      break;
    }
  }
}

















