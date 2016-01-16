/** \file
 * V.st vector board interface
 */
import processing.serial.*;

Serial createSerial() {
  // finding the right port requires picking it from the list
  // should look for one that matches "ttyACM*" or "tty.usbmodem*"
  for (String port : Serial.list()) {
    println(port);
    if (match(port, "usbmode|ACM") == null) {
      continue;
    }
    return new Serial(this, port, 9600);
  }

  println("No valid serial ports found?\n");
  return null;
}