import java.lang.System;

public float[] updateArray(float[] OrigArray) {
  
    float[] newArray = new float[OrigArray.length + 1];
    System.arraycopy(OrigArray, 0, newArray, 0, OrigArray.length);

    return newArray;
}

public float[][] updateArray(float[][] OrigArray) {
  
    float[] newArray = new float[OrigArray[1].length + 1];
    float[][] new2DArray = {newArray , newArray};
    
    System.arraycopy(OrigArray[0], 0, new2DArray[0], 0, OrigArray[0].length);
    System.arraycopy(OrigArray[1], 0, new2DArray[1], 0, OrigArray[1].length);
    
    return new2DArray;
}

public String[] updateArray(String[] OrigArray) {
  
    String[] newArray = new String[OrigArray.length + 1];
    System.arraycopy(OrigArray, 0, newArray, 0, OrigArray.length);

    return newArray;
}
