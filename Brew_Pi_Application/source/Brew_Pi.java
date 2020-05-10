import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 
import java.util.*; 
import java.io.*; 
import controlP5.*; 
import org.gicentre.utils.stat.*; 
import java.lang.ProcessBuilder; 
import java.text.DecimalFormat; 
import java.io.FileWriter; 
import java.io.IOException; 
import java.io.File; 
import java.util.*; 
import java.lang.ProcessBuilder; 
import java.lang.System; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Brew_Pi extends PApplet {









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

float timeInterval = 0.02f;
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

public void setup() {
    
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
  
    
    dataTimer.start();
    thread("updateData");
}

public void draw() {
  
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

public void Enter() {
  String enteredInterval = Interval.getText();
  timeInterval = Float.parseFloat(enteredInterval);
  
  Interval.setText(Float.toString(timeInterval));
  intervalChanged = true;
}

public void updateData(){
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

public void closeArduino(){
  
  arduino.stop();
  println("Arduino stopped");
  uploadTimer.start();

}

public void openArduino() {
  if (arduino != null){
    closeArduino();
    uploadTimer.start();
    while(!uploadTimer.isFinished()){}
  }
  println("opening");
  arduino = new Serial(this, Serial.list()[1], 57600);
  arduino.bufferUntil('\n');

}

public void Reset() {
  
  counter = -1;
  value = "";
  time = "";
  tempArray = empty;
  gravArray = empty;
  timeArray = empty;

  timeInterval = 0.02f;
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
class Timer {

  int savedTime;
  boolean running = false;
  int totalTime;

  Timer(int tempTotalTime) {
    totalTime = tempTotalTime;
  }

  public void start() {
    running = true;
    savedTime = millis();
  }
  
  public void setValue(int time){
    totalTime = time; 
  }
  
  public boolean isFinished() {
    int passedTime = millis() - savedTime;
    if (running && passedTime > totalTime) {
      running = false;
      return true;
    } else {
      return false;
    }
  }
  
  public int currentTime(){
    return millis()-savedTime;
  }
} 
// Creates or appends a file with a string



        

public void writeFile(File file, String string) {
  {
    try {
      FileWriter myWriter = new FileWriter(file, true);
      myWriter.write(string);
      myWriter.close();
    } catch (IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
    }
  }
}

//final int MIN_PER_HOUR = 60;
//final int SEC_PER_MIN = 60;

public float getTime(Calendar timeStamp) {
  String timeString = timeStamp.getTime().toString();
  
  int secIndex = timeString.lastIndexOf(':') + 1;
  int sec = Integer.parseInt(timeString.substring(secIndex, secIndex + 2));
  
  int minIndex = secIndex - 3;
  int min = Integer.parseInt(timeString.substring(minIndex, minIndex + 2));
  
  int hourIndex = minIndex - 3;
  int hour = Integer.parseInt(timeString.substring(hourIndex, hourIndex + 2));
  
  float time = ((float) hour*MIN_PER_HOUR) + ((float) min) + ((float) sec/SEC_PER_MIN);
  return time;
}



public void Initialize(String dir, String port){
  println("Starting upload of " + dir);
  //String port = "/dev/ttyACM1";  
  String[] resetArgs = new String[] {"sudo", "udevadm", "trigger"};
  String[] compileArgs = new String[] {"/bin/arduino-cli", "compile","--fqbn", "arduino:avr:uno", dir};
  String[] uploadArgs = new String[] {"/bin/arduino-cli", "upload", "-p",port,"--fqbn", "arduino:avr:uno", dir};
  
  File logFile = new File("/home/pi/Desktop/Brew_Pi/log/logFile.txt");
  File errorFile = new File("/home/pi/Desktop/Brew_Pi/log/errorFile.txt");
  
  Timer delay = new Timer(2000);
  
  try{
    ProcessBuilder reset = new ProcessBuilder(resetArgs);
    Process resetProc = reset.start();
    
    ProcessBuilder compile = new ProcessBuilder(compileArgs);
    compile.redirectOutput(logFile);
    compile.redirectError(errorFile);
    Process compileProc = compile.start();
    
    delay.start();
    
    while (!delay.isFinished()){
      ; //Wait for timer
    }
    ProcessBuilder upload = new ProcessBuilder(uploadArgs);
    upload.redirectOutput(logFile);
    upload.redirectError(errorFile);
    Process uploadProc = upload.start();
    
    println("Uploaded " + dir + " to port " + port);

  }catch(IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
  }
}


public float[] updateArray(float[] OrigArray) {
    float[] newArray = new float[OrigArray.length + 1];
    System.arraycopy(OrigArray, 0, newArray, 0, OrigArray.length);

    return newArray;
}

public String[] updateArray(String[] OrigArray) {
    String[] newArray = new String[OrigArray.length + 1];
    System.arraycopy(OrigArray, 0, newArray, 0, OrigArray.length);

    return newArray;
}
  public void settings() {  size(1024,768); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Brew_Pi" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}