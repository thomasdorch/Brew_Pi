import java.util.*;
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
