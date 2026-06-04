#include <SoftwareSerial.h>

// Define our Software Serial pins
// Arduino Pin 2 is RX (Connects to HC-05 TXD)
// Arduino Pin 3 is TX (Connects to HC-05 RXD via voltage divider)
SoftwareSerial Bluetooth(2, 3); 

unsigned long previousMillis = 0;
const long interval = 2000; // Send a test broadcast every 2 seconds

void setup() {
  // Open hardware serial communication for PC debugging
  Serial.begin(9600);
  while (!Serial); 
  
  // Open software serial communication for the HC-05
  // Default baud rate for most HC-05 modules out-of-the-box is 9600
  Bluetooth.begin(9600); 
  
  Serial.println("--- Bluetooth (HC-05) Diagnostic Test ---");
  Serial.println("1. Pair your Android phone with 'HC-05' (PIN: 1234 or 0000).");
  Serial.println("2. Open a Serial Terminal App on your phone and connect.");
  Serial.println("3. Watch for the periodic broadcast or type text in either terminal to test 2-way sync.");
}

void loop() {
  unsigned long currentMillis = millis();

  // Periodic automatic broadcast to your phone
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    Bluetooth.println("PING: Edge node is online!");
    Serial.println("Sent to Phone: PING: Edge node is online!");
  }

  // Read data from Phone (Bluetooth) and print to PC (Serial Monitor)
  if (Bluetooth.available()) {
    char incomingChar = Bluetooth.read();
    Serial.print("Received from Phone: ");
    Serial.write(incomingChar);
    Serial.println();
  }

  // Read data from PC (Serial Monitor) and send to Phone (Bluetooth)
  if (Serial.available()) {
    char outboundChar = Serial.read();
    Bluetooth.write(outboundChar);
  }
}