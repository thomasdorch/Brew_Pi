import java.lang.ProcessBuilder;


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
