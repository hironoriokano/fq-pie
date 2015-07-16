#!/bin/bash +v
ROOT_PATH=`pwd`

### install required packages ###
if [ -e /etc/redhat-release ]; then
	#CentOS6.6 - yum
	yum groupinstall -y 'development tools'
	yum install -y vim git wget bc ncurses-devel
elif [ -e /etc/lsb-release ]; then
	#Ubuntu14.04 - apt-get
	apt-get install -y git ubuntu-dev-tools build-essential autoconf automake libtool linux-headers-`uname -r` debhelper libdb-dev linux-source kernel-package
	apt-get install -y vim git wget bc ncurses-dev
fi

if [ ! -e linux-next ]; then
	echo "git clone 'linux-next' from git.kernel.org.."
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
fi

cd linux-next/
git reset --hard HEAD
rm include/net/pie.h
rm net/sched/sch_fq_pie.c

echo "coping souce files to linux-next"
cp ../pie.h 		include/net/pie.h
cp ../pkt_sched.h 	include/uapi/linux/pkt_sched.h
cp ../sch_fq_pie.c 	net/sched/sch_fq_pie.c
cp ../sch_pie.c 	net/sched/sch_pie.c
cp ../Kconfig	 	net/sched/Kconfig
cp ../sched_Makefile 	net/sched/Makefile

git add -N include/net/pie.h
git add -N net/sched/sch_fq_pie.c
git status

### make patch ###
TEMP=`head -3 Makefile`
VERSION=`echo $TEMP | awk '{print $3}'`
PATCHLEVEL=`echo $TEMP | awk '{print $6}'`
SUBLEVEL=`echo $TEMP | awk '{print $9}'`
SUBLEVEL=`expr $SUBLEVEL + 1`
PATCH_NAME=patch-${VERSION}.${PATCHLEVEL}.${SUBLEVEL}
echo "git diff > ${ROOT_PATH}/${PATCH_NAME}"
git diff > ${ROOT_PATH}/${PATCH_NAME}

### test patch ###
git reset --hard HEAD
./scripts/patch-kernel ${ROOT_PATH}/linux-next ${ROOT_PATH}

### build kernel###
echo "build kernel.."
cp ../config	.config
#cp /boot/config-`uname -r`	${ROOT_PATH}/.config

make localmodconfig #enable modules in use
make menuconfig
#go to Networking support > Networking options > QoS and/or fair queueing
#	(M)FQ
#	(M)CODEL
#	(M)FQ_CODEL
#	(M)PIE
#	(M)FQ_PIE

set -e
trap 'echo "make failed"' ERR
make -j 8

set -e
trap 'echo "make modules_install failed"' ERR
make modules_install

set -e
trap 'echo "make install failed"' ERR
make install 

cd $ROOT_PATH
mv $PATCH_NAME fq-pie.patch

if [ -L /usr/src/linux ]; then
	echo "remove current symbolic link.."
	rm /usr/src/linux
fi
ln -s ${ROOT_PATH}/linux-next /usr/src/linux
#Though you see some ERRORS, but it was installed successfully.
# reboot
