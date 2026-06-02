#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// Pin Configurations
#define RST_PIN         9
#define SS_PIN          10
#define GREEN_LED       5
#define RED_LED         6
#define BUZZER_PIN      7

// Initialize Modules
MFRC522 mfrc522(SS_PIN, RST_PIN);
SoftwareSerial Bluetooth(2, 3); // RX, TX pins on Arduino

// State tracking for basic debounce
String lastScannedUID = "";
unsigned long lastScanTime = 0;
const unsigned long debounceDelay = 8000; // 8 seconds cooldown for the same card

void setup() {
  // Initialize Serial logs for PC Debugging
  Serial.begin(9600);
  while (!Serial); // Wait for terminal connection
  
  // Initialize SPI bus and RFID hardware
  SPI.begin();
  mfrc522.PCD_Init();
  mfrc522.PCD_DumpVersionToSerial();
  // Initialize Bluetooth Serial
  Bluetooth.begin(9600);
  
  // Configure Feedback Pins
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  
  Serial.println("System Ready: Scan an RFID token...");
}

void loop() {
  // Reset debounce cache if time window has passed
  if (millis() - lastScanTime > debounceDelay) {
    lastScannedUID = "";
  }

  // Look for new physical cards present
  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  // Select one of the cards
  if ( ! mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // Parse the raw UID bytes into a clean HEX String
  String currentUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    currentUID += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    currentUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  currentUID.toUpperCase();

  // Evaluate Scan (Debounce Check)
  if (currentUID == lastScannedUID) {
    triggerErrorFeedback();
    Serial.println("Warning: Duplicate scan detected for UID: " + currentUID);
  } else {
    lastScannedUID = currentUID;
    lastScanTime = millis();
    
    // Broadcast data over Bluetooth channel to the Android Phone
    Bluetooth.println(currentUID); 
    
    triggerSuccessFeedback();
    Serial.println("Success! Broadcasted UID: " + currentUID);
  }

  // Halt PICC encryption/communication state
  mfrc522.PICC_HaltA();
}

void triggerSuccessFeedback() {
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(150); // Short crisp confirmation chirp
  digitalWrite(BUZZER_PIN, LOW);
  delay(100);
  digitalWrite(GREEN_LED, LOW);
}

void triggerErrorFeedback() {
  digitalWrite(RED_LED, HIGH);
  digitalWrite(BUZZER_PIN, HIGH);
  delay(600); // Longer, explicit warning buzz
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED, LOW);
}