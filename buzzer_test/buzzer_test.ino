// Define the pin we assigned to the buzzer
#define BUZZER_PIN 7

void setup() {
  // Start the serial monitor for debugging
  Serial.begin(9600);
  
  // Set the buzzer pin to act as an Output
  pinMode(BUZZER_PIN, OUTPUT);
  
  Serial.println("--- Buzzer Diagnostic Test ---");
  Serial.println("You should hear a double-beep every 2 seconds.");
}

void loop() {
  Serial.println("Beep Beep!");
  
  // First chirp
  digitalWrite(BUZZER_PIN, HIGH);  // Turn buzzer ON
  delay(150);                      // Keep it on for 150 milliseconds
  digitalWrite(BUZZER_PIN, LOW);   // Turn buzzer OFF
  delay(100);                      // Short pause
  
  // Second chirp
  digitalWrite(BUZZER_PIN, HIGH);  // Turn buzzer ON
  delay(150);
  digitalWrite(BUZZER_PIN, LOW);   // Turn buzzer OFF
  
  // Wait for 2 seconds before repeating
  delay(2000); 
}