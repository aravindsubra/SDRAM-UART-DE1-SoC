#define BAUDRATE 115200
#define CMD_TIMEOUT 150
#define RETRY_COUNT 8
#define ROW_SIZE 1024

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
        0, // CRC placeholder
        0  // Sequence
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
    return 0xFFFF;
}

void setup() {
    Serial.begin(BAUDRATE);
    Serial1.begin(BAUDRATE);
    while(!Serial);
    
    Serial.println(F("SDRAM Controller Interface"));
    Serial.println(F("Commands:"));
    Serial.println(F(" WAAAAAADDDD - Write 16-bit data"));
    Serial.println(F(" RAAAAAA     - Read address"));
    Serial.println(F(" DUMP        - Dump first 10 rows"));
    Serial.println(F(" TEST        - March C- test"));
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
                Serial.print("Wrote 0x");
                Serial.print(data, HEX);
                Serial.print(" @0x");
                Serial.println(addr, HEX);
            } else {
                Serial.println("Write failed");
            }
        }
        else if(input.startsWith("R") && input.length() == 7) {
            uint32_t addr = strtoul(input.substring(1).c_str(), NULL, 16);
            
            if(sendCommand('R', addr)) {
                uint16_t data = readResponse();
                if(data != 0xFFFF) {
                    Serial.print("Read 0x");
                    Serial.print(data, HEX);
                    Serial.print(" @0x");
                    Serial.println(addr, HEX);
                } else {
                    Serial.println("Read timeout");
                }
            } else {
                Serial.println("Read command failed");
            }
        }
        else if(input == "DUMP") {
            Serial.println("Dumping first 10 rows:");
            for(uint32_t row=0; row<10; row++) {
                for(uint32_t col=0; col<ROW_SIZE; col++) {
                    uint32_t addr = (row << 10) | col;
                    if(sendCommand('R', addr)) {
                        uint16_t data = readResponse();
                        Serial.print("[0x");
                        Serial.print(addr, HEX);
                        Serial.print("] = 0x");
                        Serial.println(data, HEX);
                    }
                    if(col % 16 == 0) Serial.flush();
                }
            }
            Serial.println("Dump complete");
        }
        else if(input == "TEST") {
            Serial.println("Running March C- test...");
            uint32_t errors = 0;
            
            // Write pattern
            for(uint32_t addr=0; addr<0x1FFFFF; addr++) {
                if(!sendCommand('W', addr, 0xAAAA)) errors++;
            }
            
            // Verify pattern
            for(uint32_t addr=0; addr<0x1FFFFF; addr++) {
                if(sendCommand('R', addr)) {
                    if(readResponse() != 0xAAAA) errors++;
                }
            }
            
            Serial.print("Test complete. Errors: ");
            Serial.println(errors);
        }
    }
}
