#!/bin/bash

echo "Seeing your ip adress..."
ip addr
iw dev

echo "Starting airmon-ng..."
sudo airmon-ng check kill

echo "what's your wlan? "
read wlan

sudo airmon-ng start $wlan
iw dev # cheking

echo "your mon wlan? eg:wlan0mon: "
read mon
sudo airodump-ng $mon

# we need to see the BSSID, Channel, and ESSID
# and then do the thing
