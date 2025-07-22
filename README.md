# octopi-hotspot

Scripts to setup a hotspot on a Octopi.  

This allows you to take your printer and Octopi on the road.  
When you set it up, it does not need access to internet, so you can connect to the hotspot and print.
Great for STEM events, field printing, etc.

Each Octopi creates a unique SSID based on the serial number of the cpu such as "octopi-1a2b"
The default linux login prompt is augmented with information so you can find the SSID and IP addresses:

🚀 OctoPrint Hotspot Info  
📶 SSID: octopi-1a2b  
🌐 Available at:  
 • eth0 → ``http://10.0.1.200``  
 • wlan0 → http://192.168.50.1  
 • http://octopi.lan  

The wired ethernet interface is left active.

## Installation:
1. Install Octopi using the Raspberry Pi imager
   1. Enable Wifi/SSID in setup.  I haven't figured out how to make it work without that pre-configuration.
1. clone this repository to the raspberry pi
2. Run "install.sh"
