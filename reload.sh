#!/bin/sh
set -e
trap 'echo "make failed"' ERR
make
ls *.ko
echo "compiled successfully!"

echo `tc qdisc show | grep pie`
DEV=`tc qdisc show | grep pie | awk '{print $5}'`
if [ "$DEV" != ""  ] ; then
	echo "$DEV using modules. deleting.."
	tc qdisc del dev $DEV root
fi

echo "remove modules.."
if [ "`lsmod | grep fq_pie`" != "" ] ; then
	rmmod fq_pie
fi

if [ "`lsmod | grep pie`" != "" ] ; then
	rmmod pie
fi

set -e
trap 'echo "loading modules failed"' ERR
echo "loading modules.."
insmod fq_pie.ko 
insmod pie.ko
lsmod | grep pie
