#include "HX711.h" //This library can be obtained here http://librarymanager/All#Avia_HX711

#define LOADCELL_DOUT_PIN  3
#define LOADCELL_SCK_PIN  2

HX711 scale;

float calibration_factor = 3195; //-7050 worked for my 440lb max scale setup
float objectWeight = 0;
float objectDensity = 1;
float gravity = 1;
boolean calibrated = false;

void setup() {
  Serial.begin(57600);
  Serial.println("Hydrometer Calibration");
  Serial.println("Remove all weight from scale");

  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale();
  scale.tare();	//Reset the scale to 0
  Serial.println("Place mass on scale and enter 'w'");
  
}

void loop() {

  scale.set_scale(calibration_factor); //Adjust to this calibration factor
  float weight = abs(scale.get_units(10));
  //Serial.print("Reading: ");
  //Serial.print(weight, 3);
  //Serial.print(" g"); //Change this to kg and re-adjust the calibration factor if you follow SI units like a sane person
//  Serial.print(" calibration_factor: ");
//  Serial.print(calibration_factor);
 // Serial.println();

  
  
  if(Serial.available()){
   char input = Serial.read();
    if(input == 'w'){
      objectWeight = weight;
      Serial.print("Object weight set to: "); 
      Serial.println(objectWeight);
      Serial.println("Now submerge the weight in water and enter 'a'");
    }
    if(objectWeight !=0 && input == 'a'){
      objectDensity = objectWeight / (objectWeight - weight);
      Serial.print("Object density set to: "); 
      Serial.println(objectDensity); 
      calibrated = true;
    }
  }
  
  gravity = objectDensity * (objectWeight - weight) / objectWeight;
  
  if(calibrated){
    Serial.print("("); 
    Serial.print(gravity);
    Serial.println(")");
  }
}
