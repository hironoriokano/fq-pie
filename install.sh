#!/bin/bash +v
PATCH_NAME=fq-pie.patch
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
cp ../Makefile 		net/sched/Makefile

git add -N include/net/pie.h
git add -N net/sched/sch_fq_pie.c
#git add -A
git status
#git diff
echo "making patch"
echo "git diff > ${ROOT_PATH}/${PATCH_NAME}"
git diff > ${ROOT_PATH}/${PATCH_NAME}

### assign patch ###

#echo "assign patch to ${WORK_SPACE}"
#${WORK_SPACE}/scripts/patch-kernel

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
make -j 8
make modules_install
make install 
if [ -L /usr/src/linux ]; then
	echo "remove current symbolic link.."
	rm /usr/src/linux
fi
ln -s . /usr/src/linux
#Though you see some ERRORS, but it was installed successfully.
# reboot
