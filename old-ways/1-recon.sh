#!/bin/bash

echo "Seeing your ip adress..."
ip addr
iw dev

echo "Starting airmon-ng..."
sudo airmon-ng check kill

echo "what's your interface? "
read interface

sudo airmon-ng start $interface
iw dev # cheking

echo "your mon interface? exp:wlan0mon: "
read mon
sudo airodump-ng $mon

# we need to see the BSSID, Channel, and ESSID
# and then do the thing
