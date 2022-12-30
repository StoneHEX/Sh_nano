#!/bin/sh
[ -f nano.env ] && . ./nano.env
[ ! -f nano.env ] && exit
cp aventador.conf ${JETPACK}/.
cd ${JETPACK}
sudo ./flash.sh -r -d ${JETPACK}/kernel/dtb/${DTB_FILE} aventador mmcblk0p1 


