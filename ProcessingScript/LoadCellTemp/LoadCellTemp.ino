#include "HX711.h" //This library can be obtained here http://librarymanager/All#Avia_HX711

#define LOADCELL_DOUT_PIN  3
#define LOADCELL_SCK_PIN  2
#define aref_voltage 3.3         // we tie 3.3V to ARef and measure it with a multimeter!

HX711 scale;

float calibration_factor = 3195;  //For the load cell
 
//TMP36 Pin Variables
int tempPin = 1;        //the analog pin the TMP36's Vout (sense) pin is connected to
                        //the resolution is 10 mV / degree centigrade with a
                        //500 mV offset to allow for negative temperatures
int tempReading;        // the analog reading from the sensor

void setup() {
  Serial.begin(9600);
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(-3195.f);
  scale.tare();  //Reset the scale to 0

  analogReference(EXTERNAL);  //For temp sensor
}

void loop() {
  //Reading hydrometer first:
   //Adjust to this calibration factor

  //Now reading temperature:
  tempReading = analogRead(tempPin);  
 
  // converting that reading to voltage, which is based off the reference voltage
  float voltage = tempReading * aref_voltage;
  voltage /= 1024.0; 
 
  // calculate temperature
  float temperatureC = (voltage - 0.5) * 100 ;  //converting from 10 mv per degree wit 500 mV offset
                                               //to degrees ((volatge - 500mV) times 100)
                                               
  //Make array of temp and density, then print that array                                               
  float out[] = {temperatureC,scale.get_units(5)};
  int sizeOut = 2;
  
  Serial.print("[");
  for(int i=0; i<sizeOut; i++){
    Serial.print(out[i]);
    if(i<(sizeOut-1)){
      Serial.print(", ");
    }
  }
  
  Serial.println("]");

  scale.power_down();
  delay(1000);
  scale.power_up();
}
