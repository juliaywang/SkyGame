const int JOYSTICK_X_PIN = 39;
const int JOYSTICK_Y_PIN = 32;
const int JOYSTICK_SW_PIN = 33;
const int POT_PIN = 37;
const int REPLAY_PIN = 25;

int previousReading;
int stableButton;
unsigned long changedAt = 0;

void setup() {
  Serial.begin(9600);
  analogReadResolution(12);

  pinMode(JOYSTICK_SW_PIN, INPUT_PULLUP);
  pinMode(REPLAY_PIN, INPUT_PULLUP);

  previousReading = digitalRead(REPLAY_PIN);
  stableButton = previousReading;
}

void loop() {
  int reading = digitalRead(REPLAY_PIN);

  // Ignore brief electrical changes when the button is pressed.
  if (reading != previousReading) {
    previousReading = reading;
    changedAt = millis();
  }

  if (millis() - changedAt >= 30) {
    stableButton = reading;
  }

  // Send: X,Y,Z,potentiometer,replayButton
  Serial.print(analogRead(JOYSTICK_X_PIN));
  Serial.print(",");
  Serial.print(analogRead(JOYSTICK_Y_PIN));
  Serial.print(",");
  Serial.print(digitalRead(JOYSTICK_SW_PIN));
  Serial.print(",");
  Serial.print(analogRead(POT_PIN));
  Serial.print(",");
  Serial.println(stableButton);

  delay(20);
}