#!/bin/bash
# Refs: https://blog.csdn.net/think_ycx/article/details/80800614
# create initramfs.cpio.gz
#

ROOT_DIR="/data/sandbox/"
cd $ROOT_DIR

BUSYBOX_DIR=`ls -d /data/sandbox/open_linux/busybox-*  | grep -v tar`

usage() {
	echo "Usage:"
	echo "./$0"
	echo "      01_create_initramfs \$seq \$kernel_path"
	echo "      03_install_kernel "
	echo "      04_start_kernel my_BzImage my_initrd"
	echo ""
	echo ""
	echo "Example:"
	echo "     ./$0 01_create_initramfs 01 /data/sandbox/linux-5.4.147"
	echo ""
    echo "initramfs列表:"
    find ${ROOT_DIR} -name "*cpio.gz"
}

03_install_kernel() {
	echo ""
	# 2. install kernel modules in $INITRAMFS_ID
	#cd $KERNEL_SOURCE_DIR
	#sudo make modules_install \ # 安装内核模块
	#INSTALL_MOD_PATH=$INITRAMFS_DIR  # 指定安装路径
}

01_create_initramfs() {
	SEQ=$1
	KERNEL_SOURCE_DIR=$2
	INITRAMFS_ID="initramfs-${SEQ}"
	mkdir $INITRAMFS_ID
	INITRAMFS_OUTPUT="/data/sandbox/$INITRAMFS_ID.cpio.gz"
	
	INITRAMFS_DIR="/data/sandbox/$INITRAMFS_ID/"
	
	# 1. install busybox
	cd $BUSYBOX_DIR
	sudo make  CONFIG_PREFIX=$INITRAMFS_DIR install
	
	# 2. install kernel 
	cd $KERNEL_SOURCE_DIR 
	make modules_install INSTALL_MOD_PATH=$INITRAMFS_DIR

	# 2. configure busybox
	cd $INITRAMFS_DIR
	test ! -d proc && mkdir proc
	test ! -d sys && mkdir sys
	test ! -d dev && mkdir dev
	test ! -d etc && mkdir etc
	test ! -d tmp && mkdir tmp
	test ! -d sys/kernel/debug && mkdir -p sys/kernel/debug
	test ! -d etc/init.d && mkdir etc/init.d
	
	sudo mknod dev/console c 5 1
	sudo mknod dev/ram b 1 0  
	sudo mknod dev/sda b 1 0  
	
	
	touch init
	chmod +x init
cat > init << EOF
#!/bin/sh
echo "INIT SCRIPT"
mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug
mount -t tmpfs none /tmp
mdev -s # We need this to find /dev/sda later
echo -e "nBoot took $(cut -d' ' -f1 /proc/uptime) secondsn"
exec /bin/sh
EOF
	
	touch etc/inittab
	chmod +x etc/inittab
cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a
EOF
	
	touch etc/init.d/rcS
	chmod +x etc/init.d/rcS
cat > etc/init.d/rcS << EOF
#!/bin/sh
echo "INIT SCRIPT"
# step1:
export PATH=/sbin:/bin:/usr/bin;/usr/sbin;
export HOSTNAME=muahao-host
export ll='ls -lh'
	
# step2:
mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug
mount -t tmpfs none /tmp
mdev -s # We need this to find /dev/sda later
echo -e "nBoot took $(cut -d' ' -f1 /proc/uptime) secondsn"
exec /bin/sh
EOF

	# pack it 
	find . | cpio -o --format=newc > $INITRAMFS_OUTPUT


	echo "output:"
	echo "$INITRAMFS_OUTPUT"
}

main() {
	action=$1

	if [[ $action == "01_create_initramfs" ]];then
		seq=$2
		kernel_source_path=$3
		01_create_initramfs $seq $kernel_source_path
	else
		usage
	fi
}


main $*
