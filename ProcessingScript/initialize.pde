import java.lang.ProcessBuilder;

public void Initialize(String dir, String port){
  
  //String port = "/dev/ttyACM1";  
  String[] compileArgs = new String[] {"/bin/arduino-cli", "compile","--fqbn", "arduino:avr:uno", dir};
  String[] uploadArgs = new String[] {"/bin/arduino-cli", "upload", "-p",port,"--fqbn", "arduino:avr:uno", dir};
  File logFile = new File("/home/pi/Desktop/logFile.txt");
  File errorFile = new File("/home/pi/Desktop/errorFile.txt");
  
  try{
    ProcessBuilder compile = new ProcessBuilder(compileArgs);
    compile.redirectOutput(logFile);
    compile.redirectError(errorFile);
    Process compileProc = compile.start();
    
    ProcessBuilder upload = new ProcessBuilder(uploadArgs);
    upload.redirectOutput(logFile);
    upload.redirectError(errorFile);
    Process uploadProc = upload.start();
    
    println("initialized");

  }catch(IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
  }
}
