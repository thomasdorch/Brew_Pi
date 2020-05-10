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
Textarea output;
Textfield Interval;
Textfield input;
XYChart tempPlot;
XYChart gravPlot;
Calendar timeStamp;
Timer dataTimer;
Timer uploadTimer;
DecimalFormat gravityFormat;

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
float[] timeArray = empty;

float timeInterval = 0.02;
float div;

float currentTime;
float startTime;

float objectWeight;
float objectDensity;
Float offset;
String arduinoOutput;
String arduinoInput;

boolean intervalChanged= false;
boolean calibrated = false;
int counter = -1;

//File to save data to
File file = new File("/home/pi/Desktop/Brew_Pi/log/data.txt");
String port = Serial.list()[1];

void setup() {
    size(1024,768);
    background(color(255,100));
    font = createFont("Cambria Math", 14);
    tempPlot = new XYChart(this);
    gravPlot = new XYChart(this);
    gravityFormat = new DecimalFormat("0.000");
    
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
     
    output =  control.addTextarea("output")
                    .setPosition(450,25)
                    .setSize(300,50)
                    .setFont(font)
                    .setLineHeight(14)
                    .setColorValue(0)
                    .setColorBackground(color(209))
                    .setColorForeground(color(209))
                    ;
                    
    input = control.addTextfield("input");
    input.setPosition(450,80)
         .setSize(300,18)
         .setAutoClear(false)
         .setColorValue(color(0))
         .setFont(font)
         .setFocus(true)
         .setColorBackground(color(209))
         .setColorForeground(color(209))
         .setColorActive(color(209))
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
  
     //<>//
    dataTimer.start();
    thread("updateData");
}

void draw() {
  
  if (calibrated) {

  value = arduino.readStringUntil('\n');
  //print("counter: "); println(counter);
  //print("value: "); println(value);
  if (value != null){ //<>//
    if (value.contains("`")){
      println("message from load cell sketch recieved");

      arduino.write(offset.toString());
      arduino.write('`');
      value = null;
    }

    else if (value.contains("[") && value.contains("]")){
      
      temp = value.substring(value.indexOf("[") + 1, value.indexOf(","));
      weight = value.substring(value.indexOf(",") + 2, value.indexOf("]") - 1);

      tempField.setText("Temperature: " + temp + " \u00B0C");
      gravity = objectDensity * ( objectWeight - Float.parseFloat(weight) ) / objectWeight;
      gravityField.setText("Gravity: " + gravityFormat.format(gravity));
      
      if(intervalChanged){
        int timerValue = (int) (timeInterval*60000);
        dataTimer.setValue(timerValue);
        intervalChanged = false;
      }
        
      if (dataTimer.isFinished()){
        output.setText("Reading...");
        updateData();
        dataTimer.start();
      }
    }
  }
  //Set counter to 0 to indicate that the first packet has been skipped
  if (counter < 0){
      timeStamp = Calendar.getInstance();
      currentTime = getTime(timeStamp);
      startTime = currentTime;
      print("start time: "); println(startTime);
      print("current time: "); println(currentTime);
      counter = 0;
    }
  }else{
    arduinoOutput = arduino.readStringUntil('\n');
    
    if ( arduinoOutput != null) {
      output.setText(arduinoOutput);
      if ( arduinoOutput.contains("Object weight set to: ") ) {
        objectWeight = Float.parseFloat(arduinoOutput.substring(arduinoOutput.indexOf(':') + 2, arduinoOutput.indexOf('\n'))); 
      }
      if ( arduinoOutput.contains("Object density set to: ") ) {
        objectDensity =  Float.parseFloat(arduinoOutput.substring(arduinoOutput.indexOf(':') + 2, arduinoOutput.indexOf('\n')));
        arduino.write('`');
      }
      if ( arduinoOutput.contains("Offset: ")){
        offset = Float.parseFloat(arduinoOutput.substring(arduinoOutput.indexOf(':') + 2, arduinoOutput.indexOf('\n')));
        calibrated = true;
        output.setText("Calibrated! \n Object Density: " + Float.toString(objectDensity) + ", Object Weight: " + objectWeight);
        
        closeArduino();
        output.setText("Preparing for measurement...");
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
    if(arduinoInput != null) {
        arduino.write(arduinoInput);
        arduinoInput = null;
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
  timeArray = updateArray(timeArray);
  timeStamp = Calendar.getInstance();
  currentTime = getTime(timeStamp);
  
  if(counter>0){
    
    tempArray[counter] = Float.parseFloat(temp);
    gravArray[counter] = gravity;
    timeArray[counter] = currentTime-startTime;
    tempPlot.setData(timeArray, tempArray);
    gravPlot.setData(timeArray, gravArray);

    div = timeArray[counter]- timeArray[counter-1];
    tempPlot.setYAxisAt(timeArray[counter]+(div*10));
    gravPlot.setMaxX(timeArray[counter] +(div*10));
    tempPlot.setMaxX(gravPlot.getMaxX());
    
    background(255,255,255);
    tempPlot.draw(40, 100, 950, 650);
    gravPlot.draw(40, 100, 950, 650);
  }
  
  String time = String.format("%d.%d.%d.%d",month(),day(),hour(),minute());
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
  timeArray = empty;

  timeInterval = 0.02;
  div = 0;

  currentTime = 0;
  startTime = 0;
  intervalChanged = false;
  
  background(255,255,255);
}

public void input(String text){
    
    arduinoInput = text; 
    input.clear();

}
