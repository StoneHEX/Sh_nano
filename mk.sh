#!/bin/bash
HERE=`pwd`
GCC_SERVER="releases.linaro.org"
JETPACK="${HERE}/../JetPack_4.6.3_Linux_JETSON_NANO_TARGETS/Linux_for_Tegra"
JETPACK_ROOTFS="${JETPACK}/rootfs"
SH_SOURCES="Sh_P2214163_nV-4.6.3_r32.7.3-00"
CROSS_COMPILER="gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu"
CROSS_COMPILER_ARCHIVE="${CROSS_COMPILER}.tar.xz"
LOGDIR="${HERE}/Logs"
DTB_FILE="tegra210-p3448-0002-aventador-0000-b00.dtb"
DTBO_FILE="tegra210-p3448-0000-aventador-0000-hdr40.dtbo"
DTBOUTDIR="${HERE}/nano_dtb"

usage()
{
        echo "Usage: $0 [-o <kernel> <modules> <dtbs> <all> <cleanup>]" 1>&2;
        exit 1;
}

create_aventador_config()
{
	echo "# Copyright (c) 2019-2020, StoneHEX.  All rights reserved." > ${JETPACK}/aventador.conf
	echo "#" >> ${JETPACK}/aventador.conf
	echo "# Redistribution and use in source and binary forms, with or without" >> ${JETPACK}/aventador.conf
	echo "# modification, are permitted provided that the following conditions" >> ${JETPACK}/aventador.conf
	echo "# are met:" >> ${JETPACK}/aventador.conf
	echo "#  * Redistributions of source code must retain the above copyright" >> ${JETPACK}/aventador.conf
	echo "#    notice, this list of conditions and the following disclaimer." >> ${JETPACK}/aventador.conf
	echo "#  * Redistributions in binary form must reproduce the above copyright" >> ${JETPACK}/aventador.conf
	echo "#    notice, this list of conditions and the following disclaimer in the" >> ${JETPACK}/aventador.conf
	echo "#    documentation and/or other materials provided with the distribution." >> ${JETPACK}/aventador.conf
	echo "#  * Neither the name of NVIDIA CORPORATION nor the names of its" >> ${JETPACK}/aventador.conf
	echo "#    contributors may be used to endorse or promote products derived" >> ${JETPACK}/aventador.conf
	echo "#    from this software without specific prior written permission." >> ${JETPACK}/aventador.conf
	echo "#" >> ${JETPACK}/aventador.conf
	echo "# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY" >> ${JETPACK}/aventador.conf
	echo "# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE" >> ${JETPACK}/aventador.conf
	echo "# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR" >> ${JETPACK}/aventador.conf
	echo "# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR" >> ${JETPACK}/aventador.conf
	echo "# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL," >> ${JETPACK}/aventador.conf
	echo "# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO," >> ${JETPACK}/aventador.conf
	echo "# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR" >> ${JETPACK}/aventador.conf
	echo "# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY" >> ${JETPACK}/aventador.conf
	echo "# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT" >> ${JETPACK}/aventador.conf
	echo "# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE" >> ${JETPACK}/aventador.conf
	echo "# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE." >> ${JETPACK}/aventador.conf
	echo "" >> ${JETPACK}/aventador.conf
	echo "EMMC_CFG=flash_l4t_t210_emmc_p3448.xml;" >> ${JETPACK}/aventador.conf
	echo "BLBlockSize=1048576;" >> ${JETPACK}/aventador.conf
	echo "source \"\${LDK_DIR}/p3448-0000.conf.common\";" >> ${JETPACK}/aventador.conf
	echo "T21BINARGS=\"--bins \\\"EBT cboot.bin; \"" >> ${JETPACK}/aventador.conf
	echo "CMDLINE_ADD=\"console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0 sdhci_tegra.en_boot_part_access=1\";" >> ${JETPACK}/aventador.conf
	echo "" >> ${JETPACK}/aventador.conf
	echo "ROOTFSSIZE=14GiB;" >> ${JETPACK}/aventador.conf
	echo "VERFILENAME=\"emmc_bootblob_ver.txt\";" >> ${JETPACK}/aventador.conf
	echo "DTBFILE=\"${JETPACK}/kernel/dtb/${DTB_FILE}\";" >> ${JETPACK}/aventador.conf
	echo "OTA_BOOT_DEVICE=\"/dev/mmcblk0boot0\";" >> ${JETPACK}/aventador.conf
	echo "OTA_GPT_DEVICE=\"/dev/mmcblk0boot1\";" >> ${JETPACK}/aventador.conf
}

check_for_nano_sources()
{
	cd ${HERE}
	if [ ! -d ${CROSS_COMPILER} ]; then
		echo "Cross compiler not found,downloading ${CROSS_COMPILER_ARCHIVE}"
		wget http://${GCC_SERVER}/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
		if [ $? != "0" ]; then
			echo "${CROSS_COMPILER_ARCHIVE} not found on server ${GCC_SERVER}"
			exit
		fi
		tar xf ${CROSS_COMPILER_ARCHIVE}
	fi
}

set_environment_vars()
{
	echo "JETSON_NANO_KERNEL_SOURCE=${HERE}/${SH_SOURCES}" > nano.env
	echo "TOOLCHAIN_PREFIX=${HERE}/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> nano.env
	echo "TEGRA_KERNEL_OUT=${HERE}/${SH_SOURCES}/build" >> nano.env
	echo "JETPACK=${JETPACK}" >> nano.env
	echo "JETPACK_ROOTFS=${JETPACK_ROOTFS}" >> nano.env
	echo "DTB_FILE=${DTB_FILE}" >> nano.env
	echo "DTBOUTDIR=${DTBOUTDIR}" >> nano.env
	echo "PROCESSORS=16" >> nano.env
	echo "ARCH=arm64" >> nano.env
	echo "SOURCE_PINMUX=${HERE}/dtsi/tegra210-aventador-pinmux.dtsi"  >> nano.env
	echo "SOURCE_GPIO=${HERE}/dtsi/tegra210-aventador-gpio-default.dtsi"  >> nano.env
	. ./nano.env
}

exit_error()
{
        echo "Error on step $1"
        exit -1
}

build ()
{
	[ ! -d ${LOGDIR} ] && mkdir ${LOGDIR}
	[ ! -d ${DTBOUTDIR} ] && mkdir ${DTBOUTDIR}
	cp ${SOURCE_PINMUX} ${HERE}/${SH_SOURCES}/hardware/nvidia/platform/t210/porg/kernel-dts/porg-platforms/tegra210-aventador-0000-pinmux-p3448-0002-b00.dtsi
	cp ${SOURCE_GPIO} ${HERE}/${SH_SOURCES}/hardware/nvidia/platform/t210/porg/kernel-dts/porg-platforms/tegra210-aventador-0000-gpio-p3448-0002-b00.dtsi
	cd ${SH_SOURCES}
	for i in ${STEPS}; do
		echo "Running $i"
		if [ "${i}" == "modules_install" ]; then
			sudo make -C kernel/kernel-4.9/ ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} LOCALVERSION=-tegra INSTALL_MOD_PATH=${JETPACK_ROOTFS} CROSS_COMPILE=${TOOLCHAIN_PREFIX} -j${PROCESSORS} --output-sync=target ${i} > ${LOGDIR}/log.${i} 2>&1
		else
			make -C kernel/kernel-4.9/ ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} LOCALVERSION=-tegra CROSS_COMPILE=${TOOLCHAIN_PREFIX} -j${PROCESSORS} --output-sync=target ${i} > ${LOGDIR}/log.${i} 2>&1
		fi
		if [ ! "${?}" == 0 ]; then
			exit_error ${i}
		fi
	done
	cd ${HERE}
}

export_compiled()
{
	for i in ${STEPS}; do
		if [ ${i} == "dtbs" ]; then
			echo "Copying ${DTB_FILE} to ${DTBOUTDIR} and to ${JETPACK}/kernel/dtb/"
			cp $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/boot/dts/${DTB_FILE} ${DTBOUTDIR}/.
			cp $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/boot/dts/${DTB_FILE} ${DTBOUTDIR}/kernel_${DTB_FILE}
			cp $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/boot/dts/${DTB_FILE} ${JETPACK}/kernel/dtb/.
#			echo "Copying ${DTBO_FILE} to ${DTBOUTDIR} and to ${JETPACK}/kernel/dtb/"
#			cp $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/boot/dts/${DTBO_FILE} ${DTBOUTDIR}/.
#			cp $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/boot/dts/${DTBO_FILE} ${JETPACK}/kernel/dtb/.
		fi
	done
}

# MAIN Function

while getopts ":o:" o; do
	case "${o}" in
		o)
			OPTIONS="1"
			case "${OPTARG}" in
				kernel)
					STEPS="tegra_defconfig zImage"
					;;
				modules)
					STEPS="tegra_defconfig modules modules_install"
					;;
				dtbs)
					STEPS="tegra_defconfig dtbs"
					;;
				all)
					STEPS="tegra_defconfig zImage modules dtbs modules_install"
					;;
				cleanup)
					STEPS="distclean mrproper"
					;;
				*)
					usage
					;;
			esac
			;;
		*)
			usage
			;;
	esac
done
if [ -z "${OPTIONS}" ]; then
    usage
fi

set_environment_vars
create_aventador_config
check_for_nano_sources
build
export_compiled
