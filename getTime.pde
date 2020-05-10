//Returns either the time as a decimal number (for plotting) or as a string timestamp depending on the input arguments

public float getTime(int hour, int min, int sec, char format) {
  float shortTime;
  
  if (format == 'm') {
    
    shortTime = ((float) hour*MIN_PER_HOUR) + ((float) min) + ((float) sec/SEC_PER_MIN);
    
  }else if (format == 'h'){
    
    shortTime = ((float) hour) + ((float) min/MIN_PER_HOUR) + ((float) sec/SEC_PER_MIN/MIN_PER_HOUR);
    
  }else{
    
    shortTime = 0; //Error
    println("Time format incorrect");
    
  }
  
  return shortTime;
  
}

public String getTime(int month, int day, int hour, int min, int sec){
  
  String fullTime = String.format("%d %d, %d:%d:%d",month,day,hour,min,sec);
  return fullTime;
  
}
