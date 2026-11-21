#!/bin/bash

echo "Name the data: "
read captures

echo "The channel: "
read channel

echo "Input the MAC Address: "
read macaddr

echo "Your mon interface: "
read moninterface

sudo airodump-ng -w $captures -c $channel --bssid $macaddr $moninterface
