#include <Arduino.h>

#define BUFFER_SIZE 64
uint8_t serialBuffer[BUFFER_SIZE];
uint8_t bufHead = 0;
uint8_t bufTail = 0;

void handleSerial1() {
  while(Serial1.available()) {
    serialBuffer[bufHead] = Serial1.read();
    bufHead = (bufHead + 1) % BUFFER_SIZE;
  }
}

uint16_t readResponse() {
  unsigned long start = millis();
  while(millis() - start < 50) { // 50ms timeout
    handleSerial1();
    if((bufHead - bufTail) >= 2) {
      uint8_t high = serialBuffer[bufTail];
      bufTail = (bufTail + 1) % BUFFER_SIZE;
      uint8_t low = serialBuffer[bufTail];
      bufTail = (bufTail + 1) % BUFFER_SIZE;
      return (high << 8) | low;
    }
  }
  return 0xFFFF; // Timeout indicator
}

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);
  while(!Serial); // Wait for USB connection
}

void loop() {
  if(Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toUpperCase();

    if(cmd.startsWith("W") && cmd.length() == 11) {
      // Write command: W000000A55A
      uint32_t addr = strtoul(cmd.substring(1,7).c_str(), NULL, 16);
      uint16_t data = strtoul(cmd.substring(7).c_str(), NULL, 16);
      
      Serial1.write('W');
      Serial1.write(addr >> 16);
      Serial1.write(addr >> 8);
      Serial1.write(addr);
      Serial1.write(data >> 8);
      Serial1.write(data);
      
      Serial.print("Write @");
      Serial.print(addr, HEX);
      Serial.print(": 0x");
      Serial.println(data, HEX);
    }
    else if(cmd.startsWith("R") && cmd.length() == 7) {
      // Read command: R000000
      uint32_t addr = strtoul(cmd.substring(1).c_str(), NULL, 16);
      
      for(uint8_t retry=0; retry<3; retry++) {
        Serial1.write('R');
        Serial1.write(addr >> 16);
        Serial1.write(addr >> 8);
        Serial1.write(addr);
        
        uint16_t data = readResponse();
        if(data != 0xFFFF) {
          Serial.print("Read @");
          Serial.print(addr, HEX);
          Serial.print(": 0x");
          Serial.println(data, HEX);
          return;
        }
      }
      Serial.println("Read failed after 3 retries");
    }
  }
  handleSerial1();
}
