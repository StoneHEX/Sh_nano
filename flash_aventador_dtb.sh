#!/bin/sh
[ -f nano.env ] && . ./nano.env
[ ! -f nano.env ] && exit
cd ${JETPACK}
sudo ./flash.sh -r -k DTB -d ${JETPACK}/kernel/dtb/${DTB_FILE} aventador mmcblk0p1
