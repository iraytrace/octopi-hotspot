# octopi-hotspot

Scripts to setup a hotspot on a Octopi.  
This allows you to take your printer and Octopi on the road.  
When you set it up, it does not need access to internet, so you can connect to the hotspot and print.
Great for STEM events, field printing, etc.

Each Octopi creates a unique SSID based on the serial number of the cpu such as "octopi-1a2b"

Note: You must enable Wifi in the Raspberry Pi imager when you write the SD card.
I haven't figured out how to make it work without that pre-configuration.

The wired ethernet interface is left active.

Installation:
clone the repository and run "install.sh"
