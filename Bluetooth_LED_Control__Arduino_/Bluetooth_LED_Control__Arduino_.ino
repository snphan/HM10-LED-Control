#include <SoftwareSerial.h>
// Declare int to tell where each pin is
int rxPin = 0;
int txPin = 1;
int ledPin = 7;
int boardLedPin = 13;
int fadeValue;
// Declare a software serial object called HM10 and according to documentation
// it needs the RX and TX pins as an input

SoftwareSerial HM10(rxPin, txPin); 

// Declare some variables used to store string input from the HM10

char appData;
String rawData = "";
String inData = "";

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Serial.println("HM10 serial started at 9600");
  HM10.begin(9600); //set HM10 serial at 9600 baud rate.
  //Make the LED pins an output and turn them off.
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin,LOW);
  pinMode(boardLedPin, OUTPUT);
  digitalWrite(boardLedPin,LOW);
  
}

void loop() {
  // put your main code here, to run repeatedly:
HM10.listen();
while (HM10.available() > 0) {
  appData = HM10.read();
  rawData = String(appData);
  inData = extractState(rawData);
  fadeValue = extractIntensity(rawData);
  Serial.println(fadeValue);
  Serial.write(appData); //Output appData to terminal
}
if (Serial.available()) {
  delay(10);
  HM10.write(Serial.read());
}
// If the inData value is F then turn the LED off.
if (inData == "F") {
  Serial.println("LED OFF");
  digitalWrite(boardLedPin,LOW);
  digitalWrite(ledPin, LOW);
  delay(500);
}
// if the inData value is N then turn the LED on and analog write the value.
if (inData == "N") {
  Serial.println("LED ON");
  digitalWrite(boardLedPin,HIGH);
  analogWrite(ledPin, fadeValue);
  delay(500);  
}
}


// Declare a function that spits out the state of the led on/off. Input should be 4 char string
// Example: "N001", "N255" (note that the numbers go from 0 to 255)

String extractState(String data) {
  String interprettedData = String(data[0]);
  return interprettedData;
}

// Declare a function that spits out the intensity value of the LED. Input should be 4 char string
// Example: "N001", "N255" (note that the numbers go from 0 to 255)

int extractIntensity(String data) {
  int dataSize = data.length();
  int intensityValue = 0;
  for (int i = 1; i < dataSize; i++) {
    intensityValue = intensityValue*10 + (data[i]-48);
  }
}
