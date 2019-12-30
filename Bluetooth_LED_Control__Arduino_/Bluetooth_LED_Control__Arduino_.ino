#include <SoftwareSerial.h>
#include <string.h>
// Declare int to tell where each pin is
int rxPin = 0;
int txPin = 1;
int ledPin1 = 6;
int ledPin2 = 5;
int boardLedPin = 13;
int fadeValue;
// Declare a software serial object called HM10 and according to documentation
// it needs the RX and TX pins as an input

SoftwareSerial HM10(rxPin, txPin); 

// Declare some variables used to store string input from the HM10

int i = 0;
char appData;
char rawData[4];
String inData = "";

// Initialize a varaible that keeps track of the fadeValue, if there are sudden jumps do not change
// the analog input. Make an exception for the case where we turn off the input

int prevFadeValue = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Serial.println("HM10 serial started at 9600");
  HM10.begin(9600); //set HM10 serial at 9600 baud rate.
  //Make the LED pins an output and turn them off.
  pinMode(ledPin1, OUTPUT);
  analogWrite(ledPin1,0);
  pinMode(ledPin2, OUTPUT);
  analogWrite(ledPin2,0);
  pinMode(boardLedPin, OUTPUT);
  digitalWrite(boardLedPin,LOW);
  memset(rawData, 0, sizeof rawData); // Set the rawData array to null
}

void loop() {
  // put your main code here, to run repeatedly:
HM10.listen();
// Expect a string with format letter followed by numbers N000, F000, N255
while (HM10.available() > 0 && i < 4) {
  delay(1);
  appData = HM10.read();
  rawData[i] = appData;
  i++;
}

// Extract relevant data from rawData if there is something in it. If something
// is sent then update it, if not don't do anything.
if (rawData[0] != 0) {
  inData = extractState(rawData);
  fadeValue = extractIntensity(rawData);
  i = 0; // Reset the array
  memset(rawData, 0, sizeof rawData); // Set the rawData array to null
}


// Once we have the extracted the rawData, we don't need it anymore so always set it to
// "" after extraction

 
// This is to talk to the HM10 from serial
if (Serial.available()) {
  delay(10);
  HM10.write(Serial.read());
}
// If the inData value is F then turn the LED off.
if (inData == "F") {
  //Serial.println("LED OFF");
  digitalWrite(boardLedPin,LOW);
  analogWrite(ledPin1, 0);
  analogWrite(ledPin2, 0);
  memset(rawData, 0, sizeof rawData); // Set the rawData array to null
  prevFadeValue = 0; // reset the fade value
  delay(1);
}
// if the inData value is N then turn the LED on and analog write the value.
if (inData == "N") {
  // To indicate that we are in the on loop turn the led pin 13 on
  digitalWrite(boardLedPin,HIGH);

  // If the fade value is ever 0 turn stuff off
  if (fadeValue == 0) {
    analogWrite(ledPin1, fadeValue);
    analogWrite(ledPin2, fadeValue);
    prevFadeValue = fadeValue;
  }
  // Only change the fadeValue if the difference is less than 20. Prevent jumps in output greater than 20
  if (abs(fadeValue - prevFadeValue) < 20) {
    analogWrite(ledPin1, fadeValue);
    analogWrite(ledPin2, fadeValue);
    prevFadeValue = fadeValue;
  }
  else {
    Serial.println("Input difference too high");
    fadeValue = prevFadeValue; // The current fadeValue is erroneous so reset the fadeValue to the previous value
  }
  
  delay(1);  
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
  int stringSize = data.length()-1;
  //Serial.println(stringSize);
  int intensityValue = 0;
  Serial.println(data);
  for (int i = 1; i < stringSize; i++) {
    intensityValue = intensityValue*10 + (int(data[i]) - 48);
  }
  Serial.println(intensityValue);
  return intensityValue;
}
