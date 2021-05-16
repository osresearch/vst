![Starwars game emulated with MAME](https://49.media.tumblr.com/e4f2586dd94cd36beee271fd90e8a9cc/tumblr_nxgs3gqcMc1s6w6q7o1_500.gif)

v.st vector board
====

This is the firmware and example code for the opensource harwdare
quad-DAC vector board.  It can be used with MAME to display the
vectors from 1970s and 80s games like Starwars or Asteroids
on vectorscopes and XY monitors like the Vectrex, as well as
with new art projects.

![v.st vector board prototype](https://farm6.static.flickr.com/5655/22411224411_085dc4af84.jpg)

More details at https://trmm.net/V.st and https://trmm.net/MAME

## Building the Board
A full Bill of Materials can be found [here](BOM.md).

## Flashing the Firmware
To flash the firmware, make sure you have [Teensyduino](https://www.pjrc.com/teensy/td_download.html) installed.

Clone this repository and load *teensyv/teensyv.ino* in the Arduino IDE. Next select *Teensy 3.1 / 3.2* from the *Tools -> Board* menu in the Arduino IDE. Hit verify and follow the on screen instructions to flash your Teensy with the firmware.

## Running the Demos
Make sure you have [Processing](https://processing.org/) installed and your Teensy is flashed with the firmware.

Open *processingDemo/processingDemo.pde* in Processing. As soon as you hit run and your v.st board is attached to the computer, the demo starts playing on your screen and should be visible on the device attached to your v.st.
