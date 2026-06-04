#include <SPI.h>
#include <MFRC522.h>

#define RST_PIN         9
#define SS_PIN          10

// Create MFRC522 instance
MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(9600);
  while (!Serial); // Wait for the serial port to open

  SPI.begin();         // Initialize SPI bus
  mfrc522.PCD_Init();  // Initialize the MFRC522 module

  Serial.println("--- RFID Diagnostic Test ---");
  
  // This is the most important line for debugging:
  Serial.print("Reader Firmware Version: ");
  mfrc522.PCD_DumpVersionToSerial();
  
  Serial.println("Waiting for card...");
}

void loop() {
  // Look for new cards
  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  // Select one of the cards
  if ( ! mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // If we get here, a card was successfully read!
  Serial.print("Success! Card UID: ");
  
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    Serial.print(mfrc522.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(mfrc522.uid.uidByte[i], HEX);
  }
  
  Serial.println();
  
  // Halt to prevent constant re-reading of the same card in a single tap
  mfrc522.PICC_HaltA();
}