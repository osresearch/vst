![Qix demo](https://c2.staticflickr.com/6/5733/22887277280_fdbe3bba10_z.jpg)
# Vector drawing demo

This is a quick demo of how to use the Processing `Serial` class to
write to the v.st board on the serial port and draw vectors on the
Vectrex or vectorscope display.  There are a few different demos
included -- uncomment `qix_draw()`, `swarm_draw()` or `spiral_draw()`
to see the different patterns.

![Recursive spiral](https://farm6.staticflickr.com/5629/23427063830_41b39708ef_z_d.jpg)

The recursive spiral art demo is by Jacob Joaquin and
demonstrates a class to create replicated shapes.

## For vi users:

To the tab key to create 2 spaces (to make processing-IDE-friendly
code), add the following to the top of each .pde file:

```c
// vim: set ts=2 expandtab:
````

And then add the following line to your .vimrc or .exrc, whichever
you use:

```
:set modelines=1 
```
