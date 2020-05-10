// Creates or appends a file with a string

import java.io.FileWriter;
import java.io.IOException;
import java.io.File;        

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
