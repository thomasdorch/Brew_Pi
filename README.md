# Brew Pi
This is a project to create a continuous monitor for homebrewing. Currently it runs on a Raspberry Pi and uses an arduino connected via to collect data about the brew and display it on a continuous plot. 

The program is written in Processing and requires the Arduino CLI to programatically upload Arduino sketches as needed.

## Libraries Used
### Arduino Libraries
   - [HX711 Load Cell Amplifier Library] from bogde
   
### Processing Libraries
   - [Control P5 GUI Library] from sojamo
   - [giCentre Utils] from gicentre

[HX711 Load Cell Amplifier Library]: https://github.com/bogde/HX711
[Control P5 GUI Library]: https://github.com/sojamo/controlp5
[giCentre Utils]: https://www.gicentre.net/utils

## Current Supported Sensors
  - Temperature Sensor (TMP36)
  - Electronic Hydrometer (Using Mini Load Cell TAL221 and Load Cell Amplifier HX711)

## Sensors I would like to add in the future
  - pH Sensor 
  - Refractometer
