# Apple2Flat

This is a CC65 framework for building C or Assembly programs to run on the Apple II.

**This is a work in progress, and is not yet ready for general use.**

Goals:

* Remove all dependencies on Apple DOS and BASIC.
* Unrestricted access to the whole memory space. No need to tiptoe around the OS.
* Boot from standard format 16-sector floppy disks, or audio tape.
* Small boot sector, giving more space on the disk for your program and its data.
* Utility library for text, graphics, sound, keyboard, and joystick.
* Usable for both C and assembly projects.
