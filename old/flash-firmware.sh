#!/bin/bash
first_dir=$(pwd)
cd ${HOME}/src/qmk_firmware
qmk compile 2>&1 > /dev/null
echo "Press Raise+Rekt in the next 5 seconds..."
sleep 5
sudo dfu-programmer atmega32u4 erase --force
sudo dfu-programmer atmega32u4 flash keebio_iris_rev4_s-newman.hex
sudo dfu-programmer atmega32u4 reset
cd ${first_dir}
