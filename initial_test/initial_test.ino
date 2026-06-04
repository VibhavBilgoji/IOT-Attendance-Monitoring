#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// --- Pin Configurations ---
#define RST_PIN         9
#define SS_PIN          10
#define RX_PIN          2  // Connects to HC-05 TXD
#define TX_PIN          3  // Connects to HC-05 RXD (via voltage divider)
#define GREEN_LED       5
#define RED_LED         6
#define BUZZER_PIN      7

// --- Initialize Modules ---
MFRC522 mfrc522(SS_PIN, RST_PIN);
SoftwareSerial Bluetooth(RX_PIN, TX_PIN); 

// --- State Variables ---
String lastScannedUID = "";
unsigned long lastScanTime = 0;
const unsigned long debounceDelay = 8000; // 8 seconds cooldown for the same card

void setup() {
  // Initialize PC Serial Monitor
  Serial.begin(9600);
  
  // Explicitly configure hardware control lines
  pinMode(RST_PIN, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Perform a clean physical hardware toggle on the reader chip
  digitalWrite(RST_PIN, LOW);
  delay(20);
  digitalWrite(RST_PIN, HIGH);
  delay(20);
  
  // Initialize High-Speed SPI Bus & RFID
  SPI.begin();
  mfrc522.PCD_Init();
  
  // Log the chip communication state
  Serial.print("Reader Connection verified. Chip Signature: ");
  mfrc522.PCD_DumpVersionToSerial();
  
  // Initialize Bluetooth module and immediately put its listener to sleep
  Bluetooth.begin(9600);
  Bluetooth.stopListening(); 
  
  Serial.println("Smart Attendance System Active. Scan card...");
}

void loop() {
  // 1. Clear duplicate-scan cache after window cooldown expires
  if (millis() - lastScanTime > debounceDelay) {
    lastScannedUID = "";
  }

  // 2. Poll for physical cards present on the antenna field
  if ( ! mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // 3. Extract card serial bytes into a hex string format
  String currentUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    currentUID += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    currentUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  currentUID.toUpperCase();

  // 4. Process identity state and fire visual feedback
  if (currentUID == lastScannedUID) {
    triggerError();
    Serial.println("Duplicate Scan Prevented: " + currentUID);
  } else {
    lastScannedUID = currentUID;
    lastScanTime = millis();
    
    Serial.println("Valid Card Detected: " + currentUID);
    
    // Wake up the SoftwareSerial register to broadcast the data string safely
    Bluetooth.listen();
    delay(10); // Let the serial registry stabilize
    Bluetooth.println(currentUID); 
    delay(10); // Ensure the full buffer pipeline clears out
    Bluetooth.stopListening(); // Suspend interrupts so SPI can listen smoothly again
    
    triggerSuccess();
  }

  // 5. Safely drop communication state with the card
  mfrc522.PICC_HaltA();
}

// --- Visual and Audio Indication Modules ---
void triggerSuccess() {
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(150); 
  digitalWrite(BUZZER_PIN, LOW);
  delay(100);
  digitalWrite(GREEN_LED, LOW);
}

void triggerError() {
  digitalWrite(RED_LED, HIGH);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(600); 
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED, LOW);
}