#!/bin/bash

# This file is part of Espruino, a JavaScript interpreter for Microcontrollers
#
# Copyright (C) 2013 Gordon Williams <gw@pur3.co.uk>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# ----------------------------------------------------------------------------------------
# Creates a binary file containing both Espruino and the bootloader
# ----------------------------------------------------------------------------------------

cd `dirname $0` # scripts
cd ..            # main dir
BASEDIR=`pwd`

ESPRUINOFILE=espruino_espruino_1v1.bin
BOOTLOADERFILE=bootloader_espruino_1v1.bin
IMGFILE=espruino_full.bin
rm -f $ESPRUINOFILE $BOOTLOADERFILE $IMGFILE

export ESPRUINO_1V1=1
# export DEBUG=1
export RELEASE=1

BOOTLOADER=1 make clean
BOOTLOADER=1 make || { echo 'Build failed' ; exit 1; }

make clean
make || { echo 'Build failed' ; exit 1; }

cd $BASEDIR/scripts
BOOTLOADERSIZE=`python -c "import common;print common.get_bootloader_size()"`
cd $BASEDIR
IMGSIZE=$(expr $BOOTLOADERSIZE + $(stat -c%s "$ESPRUINOFILE"))

echo ---------------------
echo Image Size = $IMGSIZE

echo ---------------------
echo Create blank image
echo ---------------------
tr "\000" "\377" < /dev/zero | dd bs=1 count=$IMGSIZE of=$IMGFILE || { echo 'Build failed' ; exit 1; }

echo Add bootloader
echo ---------------------
dd bs=1 if=$BOOTLOADERFILE of=$IMGFILE conv=notrunc || { echo 'Build failed' ; exit 1; }

echo Add espruino
echo ---------------------
dd bs=1 seek=$BOOTLOADERSIZE if=$ESPRUINOFILE of=$IMGFILE conv=notrunc || { echo 'Build failed' ; exit 1; }

echo ---------------------
echo Finished! Written to $IMGFILE
echo ---------------------

echo python scripts/stm32loader.py -b 460800 -ewv $IMGFILE
python scripts/stm32loader.py -b 460800 -ewv $IMGFILE
