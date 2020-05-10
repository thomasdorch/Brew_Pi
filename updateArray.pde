import java.lang.System;

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
