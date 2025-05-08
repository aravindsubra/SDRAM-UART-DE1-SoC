#include <Arduino.h>

#define BAUDRATE 115200
#define CMD_TIMEOUT 150
#define RETRY_COUNT 5
#define SDRAM_SIZE 0x7FFFF  // 8MB for MT48LC4M16A2-6A

// CRC-8 with polynomial 0x07
uint8_t crc8(const uint8_t *data, uint8_t len) {
  uint8_t crc = 0x00;
  while(len--) {
    crc ^= *data++;
    for(uint8_t i=0; i<8; i++)
      crc = (crc & 0x80) ? (crc << 1) ^ 0x07 : crc << 1;
  }
  return crc;
}

bool sendCommand(char cmd, uint32_t addr, uint16_t data=0) {
  uint8_t packet[8] = {
    (uint8_t)cmd,
    (uint8_t)(addr >> 16),
    (uint8_t)(addr >> 8),
    (uint8_t)addr,
    (uint8_t)(data >> 8),
    (uint8_t)data,
    0,  // CRC placeholder
    0   // Sequence number
  };
  packet[6] = crc8(packet, 6);

  for(uint8_t retry=0; retry<RETRY_COUNT; retry++) {
    Serial1.write(packet, 8);
    
    unsigned long start = millis();
    while(millis() - start < CMD_TIMEOUT) {
      if(Serial1.available() >= 3) {
        uint8_t response[3];
        Serial1.readBytes(response, 3);
        if(response[2] == crc8(response, 2)) {
          return true;
        }
      }
    }
  }
  return false;
}

uint16_t readResponse() {
  unsigned long start = millis();
  while(millis() - start < CMD_TIMEOUT) {
    if(Serial1.available() >= 2) {
      uint8_t data[2];
      Serial1.readBytes(data, 2);
      return (data[0] << 8) | data[1];
    }
  }
  return 0x0000;
}

void setup() {
  Serial.begin(BAUDRATE);   // USB Serial
  Serial1.begin(BAUDRATE);  // FPGA UART
  while(!Serial); // Wait for serial monitor
  
  Serial.println(F("SDRAM Controller - MT48LC4M16A2-6A Interface"));
  Serial.println(F("Commands:"));
  Serial.println(F("  WAAAAAADDDD - Write data (e.g. W000000A55A)"));
  Serial.println(F("  RAAAAAA     - Read address (e.g. R000000)"));
  Serial.println(F("  DUMP        - First 10 rows dump (0x0000-0x09FF)"));
  Serial.println(F("  TEST        - March C- test on first 10 rows (0x0000-0x09FF)"));
}

void loop() {
  if(Serial.available()) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    input.toUpperCase();

    if(input.startsWith("W") && input.length() == 11) {
      uint32_t addr = strtoul(input.substring(1,7).c_str(), NULL, 16);
      uint16_t data = strtoul(input.substring(7).c_str(), NULL, 16);
      
      if(sendCommand('W', addr, data)) {
        Serial.print("Write @0x");
        Serial.print(addr, HEX);
        Serial.print(": 0x");
        Serial.println(data, HEX);
      } else {
        Serial.println("Write failed: Check connections/retries");
      }
    }
    else if(input.startsWith("R") && input.length() == 7) {
      uint32_t addr = strtoul(input.substring(1).c_str(), NULL, 16);
      
      if(sendCommand('R', addr)) {
        uint16_t data = readResponse();
        Serial.print("Read @0x");
        Serial.print(addr, HEX);
        Serial.print(": 0x");
        Serial.println(data, HEX);
      } else {
        Serial.println("Read failed: Address invalid/refresh issue");
      }
    }
    else if(input == "DUMP") {
      Serial.println("BEGIN DUMP (0x0000-0x09FF)");
      for(uint32_t addr=0x0000; addr <= 0x09FF; addr++) {
        if(sendCommand('R', addr)) {
          uint16_t data = readResponse();
          Serial.print("[0x");
          Serial.print(addr, HEX);
          Serial.print("] = 0x");
          Serial.println(data, HEX);
        }
      }
      Serial.println("END DUMP");
    }
    else if(input == "TEST") {
      Serial.println("Starting March Test on 0x0000-0x09FF...");
      uint32_t errors = 0;
      for(uint32_t addr=0x0000; addr <= 0x09FF; addr++) {
        if(!sendCommand('W', addr, 0xFFFF)) errors++;
      }
      for(uint32_t addr=0x0000; addr <= 0x09FF; addr++) {
        if(sendCommand('R', addr)) {
          if(readResponse() != 0xFFFF) errors++;
        }
      }
      Serial.print("March Test Complete. Errors: ");
      Serial.println(errors);
    }
  }
}

