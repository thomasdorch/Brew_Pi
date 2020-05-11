import processing.serial.*;
import java.util.*;
import java.io.*;
import controlP5.*;
import org.gicentre.utils.stat.*;
import java.lang.ProcessBuilder;
import java.text.DecimalFormat;

//Initialize GUI controllers
ControlP5 control;
Textarea tempField;
Textarea gravityField;
Textarea ArduinoOutputArea;
Textfield Interval;
Textfield input;
XYChart tempPlot;
XYChart gravPlot;
Calendar timeStamp;
Timer dataTimer;
Timer uploadTimer;
DecimalFormat threeDecimals;
DecimalFormat twoDecimals;

//Initialize Arduino connection
Serial arduino;
String mainPath = "/home/pi/Desktop/Brew_Pi/src/Run_Instrument";
String calPath = "/home/pi/Desktop/Brew_Pi/src/Calibrate";

final int MIN_PER_HOUR = 60;
final int SEC_PER_MIN = 60;
String temp;
String weight;
float gravity;


PFont font;

String value = "";
String time;
float[] empty = {};
float[] tempArray = empty;
float[] gravArray = empty;
float[] timeArray_inMinutes = empty;
float[] timeArray_inHours = empty;

float timeInterval = 0.02;
float div;

float currentTime_inMinutes;
float currentTime_inHours;
float currentTimeRelative_inMinutes;
float currentTimeRelative_inHours;
float startTime_inMinutes;
float startTime_inHours;
int days = 0;
int currentDay;
int startDay;
float objectWeight;
float objectDensity;
Float offset;
String rawArduinoOutput;  //Actual output from Arduino
String consoleText;  //Arduino and system output to display in message window
String rawArduinoInput;  //Actual input to Arduino

boolean intervalChanged = false;
boolean calibrated = false;
int counter = -1;
boolean inHours = false;

//File to save data to
File file = new File("/home/pi/Desktop/Brew_Pi/log/data.txt");
String port = Serial.list()[1];

void setup() {
    size(1024,768);
    background(color(255,100));
    font = createFont("Cambria Math", 14);
    tempPlot = new XYChart(this);
    gravPlot = new XYChart(this);
    threeDecimals = new DecimalFormat("0.000");
    twoDecimals = new DecimalFormat("0.00");
    
    ControlP5 control = new ControlP5(this);
    tempField = control.addTextarea("temp")
                       .setPosition(250,25)
                       .setSize(150,30)
                       .setFont(font)
                       .setLineHeight(14)
                       .setColorValue(color(0))
                       .setColorBackground(color(209))
                       .setColorForeground(color(209));
                        ;
    tempField.setText("Loading...");
                
    gravityField = control.addTextarea("gravity")
                          .setPosition(75,25)
                          .setSize(150,30)
                          .setFont(font)
                          .setLineHeight(14)
                          .setColorValue(0)
                          .setColorBackground(color(209))
                          .setColorForeground(color(209))
                          ;
    gravityField.setText("Loading...");
                
    Interval = control.addTextfield("Interval");
    Interval.setLabel("Time Interval (minutes)").setFont((createFont("Cambria Math",11)))
            .setPosition(800,25)
            .setSize(100,30)
            .setAutoClear(false)
            .setColorValue(color(0))
            .setFont(font)
            .setFocus(false)
            .setColorBackground(color(209))
            .setColorForeground(color(209))
            .setColorActive(color(209))
            .getCaptionLabel().align(ControlP5.CENTER,ControlP5.TOP_OUTSIDE).setColor(0).toUpperCase(false)
            ;
    Interval.setText(Float.toString(timeInterval));
    
    control.addBang("Enter")
     .setPosition(Interval.getPosition()[0] + 25 ,Interval.getPosition()[1] + 33)
     .setSize(50,15).setColorForeground(color(128))
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setColor(color(0))
     ;  
     control.addBang("Reset")
     .setPosition(950,40)
     .setSize(50,25)
     .setFont(createFont("Cambria Math", 14))
     .setColorBackground(color(255,0,0))
     .setColorForeground(color(255,0,0))
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setColor(color(0)).toUpperCase(false)
     ;
     
    ArduinoOutputArea =  control.addTextarea("ArduinoOutputArea")
                    .setPosition(450,25)
                    .setSize(300,50)
                    .setFont(font)
                    .setLineHeight(14)
                    .setColorValue(0)
                    .setColorBackground(color(209))
                    .setColorForeground(color(209))
                    .setScrollForeground(color(0))
                    .setScrollBackground(color(200))
                    ;
                    
    input = control.addTextfield("ArduinoInputField");
    input.setPosition(450,80)
         .setSize(300,18)
         .setAutoClear(false)
         .setColorValue(color(0))
         .setFont(font)
         .setFocus(true)
         .setColorBackground(color(209))
         .setColorForeground(color(209))
         .setColorActive(color(209))
         .setColorCursor(color(0))
         ;
                     
    tempPlot.setLineColour(color(50,200,200));
    tempPlot.setLineWidth(2);
    tempPlot.showXAxis(true);
    tempPlot.showYAxis(true);
    tempPlot.setMinY(0);
    tempPlot.setYAxisLabel("Temperature (\u00B0C)");
    tempPlot.setXAxisLabel("Time (minutes)");
    
    
    gravPlot.setLineColour(color(5,216,96));
    gravPlot.setLineWidth(2);
    gravPlot.showXAxis(true);
    gravPlot.showYAxis(true);
    gravPlot.setMinY(0);
    gravPlot.setYAxisLabel("Specific Gravity");
    gravPlot.setXAxisLabel("Time (minutes)");
             
    dataTimer = new Timer(2000);
    uploadTimer = new Timer(10000);
    
    Initialize(calPath, port);
    uploadTimer.start();
    
    while(!uploadTimer.isFinished()){
      ; //wait for timer to finish
    }

    openArduino();
    arduino.bufferUntil('\n');
  
    
    dataTimer.start();
    //thread("updateData");
}

void draw() {
  
  if (calibrated) {

    value = arduino.readStringUntil('\n');
    //print("counter: "); println(counter);
    //print("value: "); println(value);
    if (value != null){
      
      if (value.contains("`")){
        println("message from load cell sketch recieved");
  
        arduino.write(offset.toString());
        arduino.write('`');
        value = null;
      }
  
      //Parses serial putput from the Arduino and adds it to the plot/log file
      else if (value.contains("[") && value.contains("]")){
        
        temp = value.substring(value.indexOf("[") + 1, value.indexOf(","));
        weight = value.substring(value.indexOf(",") + 2, value.indexOf("]") - 1);
  
        tempField.setText("Temperature: " + temp + " \u00B0C");
        gravity = objectDensity * ( objectWeight - Float.parseFloat(weight) ) / objectWeight;
        gravityField.setText("Gravity: " + threeDecimals.format(gravity));
        
        //If the interval between measurements has elapsed, change the value of the dataTimer
        if(intervalChanged){
          int timerValue = (int) (timeInterval*60000);
          dataTimer.setValue(timerValue);
          intervalChanged = false;
        }
          
        if (dataTimer.isFinished()){
          
          //Set counter to 0 to indicate that the first packet has been skipped and gets sets the start time
          if (counter < 0){
            
            int hour = hour();
            int min = minute();
            int sec = second();
            currentDay = day();
            startDay = currentDay;
            currentTime_inHours = getTime(hour,min,sec,'m');
            startTime_inMinutes = currentTime_inHours;
            startTime_inHours = getTime(hour,min,sec,'h');
            
            print("start time: "); println(startTime_inMinutes);
            print("current time: "); println(currentTime_inHours);
            
            counter = 0;
            dataTimer.start();
            
          }else{
          
            updateData();
            dataTimer.start();
            
            //if ( (inHours == false) && (!( abs(timeInterval - div) < 0.03 ) && (div != 0))  ){
            //  timeInterval = div;
            //  Interval.setText(twoDecimals.format(div));
            //  println("Interval set");
            //}
          }
       }
      }
    }
    
  }else{
    rawArduinoOutput = arduino.readStringUntil('\n');

    if ( rawArduinoOutput != null) {
      
      if (consoleText != null){
        consoleText = consoleText + rawArduinoOutput; 
        
      }else {
        consoleText = rawArduinoOutput;
      }
      
      ArduinoOutputArea.setText(consoleText).scroll(1);
      
      if ( rawArduinoOutput.contains("Object weight set to: ") ) {
        objectWeight = Float.parseFloat(rawArduinoOutput.substring(rawArduinoOutput.indexOf(':') + 2, rawArduinoOutput.indexOf('\n'))); 
      }
      if ( rawArduinoOutput.contains("Object density set to: ") ) {
        objectDensity =  Float.parseFloat(rawArduinoOutput.substring(rawArduinoOutput.indexOf(':') + 2, rawArduinoOutput.indexOf('\n')));
        arduino.write('`');
        ArduinoOutputArea.setText(consoleText + "Preparing for measurement...");
      }
      if ( rawArduinoOutput.contains("Offset: ")){
        offset = Float.parseFloat(rawArduinoOutput.substring(rawArduinoOutput.indexOf(':') + 2, rawArduinoOutput.indexOf('\n')));
        calibrated = true;
        ArduinoOutputArea.setText(consoleText + "Calibrated!"+ "\n");
        ArduinoOutputArea.setText( "Object Density: " + Float.toString(objectDensity) + ", Object Weight: " + objectWeight);
        
        closeArduino();
        
        uploadTimer.start();
        while (!uploadTimer.isFinished()){
          ;
        }
        Initialize(mainPath, port);
        
        uploadTimer.start();
        while (!uploadTimer.isFinished()){
          ; 
        }
        
        openArduino();
        
        arduino.write('`');
      }
    }
    
    if(rawArduinoInput != null) {
        arduino.write(rawArduinoInput);
        rawArduinoInput = null;
      }
  }
}

void Enter() {
  String enteredInterval = Interval.getText();
  timeInterval = Float.parseFloat(enteredInterval);
  
  Interval.setText(Float.toString(timeInterval));
  intervalChanged = true;
}

void updateData(){
  
tempArray = updateArray(tempArray);
gravArray = updateArray(gravArray);
timeArray_inMinutes = updateArray(timeArray_inMinutes);
timeArray_inHours = updateArray(timeArray_inHours);
currentDay = day();
//print("currrent time: "); println(currentTime);
//print("start time(m): "); println(startTime_inMinutes);
//print("start time(h): "); println(startTime_inHours);

currentTime_inMinutes = getTime(hour(),minute(),second(),'m');

currentTime_inHours = getTime(hour(),minute(),second(),'h');
days = (currentDay-startDay);

if ( currentTime_inHours < startTime_inHours ){
  currentTimeRelative_inMinutes = ( currentTime_inMinutes ) + days*(24*MIN_PER_HOUR - startTime_inMinutes);
  currentTimeRelative_inHours = ( currentTime_inHours ) + days*(24 - startTime_inHours);

} else {
  currentTimeRelative_inHours =  currentTime_inHours - startTime_inHours + days*24;
  currentTimeRelative_inMinutes = currentTime_inMinutes -startTime_inMinutes  + days*24*MIN_PER_HOUR;

}


if(counter > 0){
  
  tempArray[counter] = Float.parseFloat(temp);
  gravArray[counter] = gravity;
  timeArray_inMinutes[counter] = currentTimeRelative_inMinutes;
  timeArray_inHours[counter] = currentTimeRelative_inHours;
  
  
  if (!inHours) {
    div = timeArray_inMinutes[counter]- timeArray_inMinutes[counter-1];
    tempPlot.setData(timeArray_inMinutes, tempArray);
    gravPlot.setData(timeArray_inMinutes, gravArray);
    tempPlot.setYAxisAt(timeArray_inMinutes[counter]+(div*10));
    gravPlot.setMaxX(timeArray_inMinutes[counter] +(div*10));
    tempPlot.setMaxX(gravPlot.getMaxX());
    
    if ( abs(currentTime_inMinutes - startTime_inMinutes) > 1 ){
      
      tempPlot.setXAxisLabel("Time (hours)");
      gravPlot.setXAxisLabel("Time (hours)");
      inHours = true;
      
    }
    
  }else if (inHours){
    
    div = timeArray_inHours[counter]- timeArray_inHours[counter-1];
    tempPlot.setData(timeArray_inHours, tempArray);
    gravPlot.setData(timeArray_inHours, gravArray);
    div = timeArray_inHours[counter]- timeArray_inHours[counter-1];
    tempPlot.setYAxisAt(timeArray_inHours[counter]+(div*10));
    gravPlot.setMaxX(timeArray_inHours[counter] +(div*10));
    tempPlot.setMaxX(gravPlot.getMaxX());
      
  }

  
  
  background(255,255,255);
  tempPlot.draw(40, 100, 950, 650);
  gravPlot.draw(40, 100, 950, 650);
}


String time = getTime(month(),day(),hour(),minute(),second());
//Write the data to a text file
String output = temp + ", " + gravity + ", " + time + "\n" ;
writeFile(file ,output );
counter++;
}

void closeArduino(){
  
  arduino.stop();
  println("Arduino stopped");
  uploadTimer.start();

}

void openArduino() {
  
  if (arduino != null){
    closeArduino();
    uploadTimer.start();
    
    while(!uploadTimer.isFinished()){}
  }
  
  println("opening");
  arduino = new Serial(this, Serial.list()[1], 57600);
  arduino.bufferUntil('\n');
}

void Reset() {
  
  counter = -1;
  value = "";
  time = "";
  tempArray = empty;
  gravArray = empty;
  timeArray_inMinutes = empty;

  timeInterval = 0.02;
  div = 0;

  currentTime_inHours = 0;
  startTime_inHours = 0;
  startTime_inMinutes = 0;
  intervalChanged = false;
  
  background(255,255,255);
}

public void ArduinoInputField(String text){
  
    rawArduinoInput = text; 
    input.clear();
    
}
