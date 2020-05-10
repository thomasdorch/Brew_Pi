class Timer {

  int savedTime;
  boolean running = false;
  int totalTime;

  Timer(int tempTotalTime) {
    totalTime = tempTotalTime;
  }

  void start() {
    running = true;
    savedTime = millis();
  }
  
  void setValue(int time){
    totalTime = time; 
  }
  
  boolean isFinished() {
    int passedTime = millis() - savedTime;
    if (running && passedTime > totalTime) {
      running = false;
      return true;
    } else {
      return false;
    }
  }
  
  int currentTime(){
    return millis()-savedTime;
  }
} 
