#!/bin/bash
# Refs: 
# - https://blog.csdn.net/think_ycx/article/details/80800614
# - 编译内核+BusyBox定制一个Linux提供ssh和web服务: https://blog.51cto.com/chenpipi/1390874

ROOTFS_ID="rootfs-01"
mkdir $ROOTFS_ID

BUSYBOX_DIR=`ls -d  /data/sandbox/open_linux/busybox*  | grep -v tar`
IMG_NAME="$ROOTFS_ID.raw"
IMG_PATH="/data/sandbox/vm/${IMG_NAME}"
IMG_MOUNTPOINT="/data/sandbox/vm/$ROOTFS_ID/"
KERNEL_SOURCE_DIR="/usr/src/linux-5.4.147/"
BZ_IMAGE="/data/sandbox/linux-5.4.147/arch/x86_64/boot/bzImage"


install_modules() {
	# 2. install kernel modules in $ROOTFS_ID
	cd $KERNEL_SOURCE_DIR
	sudo make modules_install \ # 安装内核模块
	INSTALL_MOD_PATH=$IMG_MOUNTPOINT  # 指定安装路径
}

pre_clean_up() {
	umount $ROOTFS_ID
	rm -fr $IMG_PATH
}

create_rootfs_img() {
    # 0. Create a img
	qemu-img create -f raw ${IMG_PATH} 8096M
	mkfs -t ext4 ${IMG_PATH}
	mkdir $IMG_MOUNTPOINT
	mount -t ext4 -o loop ${IMG_PATH} ${IMG_MOUNTPOINT}
	
	# 1. install busybox
	cd $BUSYBOX_DIR
	sudo make  CONFIG_PREFIX=$IMG_MOUNTPOINT install
	
	# 2. install_modules
	# install_modules
	
	# 4 rootfs mknod and create $ROOTFS_ID.cpio.gz
	cd $IMG_MOUNTPOINT
	test ! -d proc && mkdir proc
	test ! -d sys && mkdir sys
	test ! -d dev && mkdir dev
	test ! -d etc && mkdir etc
	test ! -d tmp && mkdir tmp
	test ! -d mnt && mkdir mnt
	test ! -d root && mkdir root
	test ! -d sys/kernel/debug && mkdir -p sys/kernel/debug
	test ! -d etc/init.d && mkdir etc/init.d
	
	sudo mknod -m 600 dev/console c 5 1
	sudo mknod dev/ram b 1 0  
	sudo mknod dev/sda b 1 0  
	
	
	touch etc/inittab
	chmod +x etc/inittab
#cat > etc/inittab << EOF
#:sysinit:/etc/rc.d/rc.sysinit
#::respawn:/sbin/getty 19200 tty1
#::respawn:/sbin/getty 19200 tty2
#::respawn:/sbin/getty 19200 tty3
#::respawn:/sbin/getty 19200 tty4
#::respawn:/sbin/getty 19200 tty5
#::respawn:/sbin/getty 19200 tty6
#::ctrlaltdel:/sbin/reboot
#::shutdown:/bin/umount -a -r
#EOF
	

# V1
	###########################
    #    inittab              #
    ###########################
cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a
EOF

	###########################
    # root/.bashrc            #
    ###########################
	touch root/.bashrc
	chmod 644 root/.bashrc
cat > root/.bashrc << EOF
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
EOF

	###########################
    # passwd                  #
    ###########################
touch etc/passwd
chmod 644 etc/passwd
cat > etc/passwd << EOF
root:x:0:0:root:/root:/bin/bash
EOF

touch etc/group
chmod 644 etc/group
cat > etc/group << EOF
root:x:0:
EOF

touch etc/shadow
chmod 400 etc/shadow
cat > etc/shadow << EOF
root:$6$rounds=5000$ZIphQ93q4FEEpCS2$dIo.F.YCbQyIXyc2ztaMICrorRwDjGz/TfPEeR1kX6YZc2LyTeRKstnE62zNDGgerDBolPAgwtQ0ij1QTUdPP/:18876:0:99999:7:::
EOF


	###########################
    # run when vm start       #
    ###########################
	touch etc/init.d/rcS
	chmod +x etc/init.d/rcS
cat > etc/init.d/rcS << EOF
#!/bin/sh
echo -e "\tWelcome to \033[36m AhaoMu-Linux\033[0m"

# step1:
export PATH=/sbin:/bin:/usr/bin:/usr/sbin;
export HOSTNAME=muahao-host
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'
source /root/.bashrc

# step2:
mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug
mount -t tmpfs none /tmp
mdev -s # We need this to find /dev/sda later
echo -e "nBoot took $(cut -d' ' -f1 /proc/uptime) secondsn"
exec /bin/sh

EOF
}

 start_vm() {
	# 6 start qemu
	echo "BZ_IMAGE:$BZ_IMAGE"
	echo "IMG_PATH:$IMG_PATH"
	sleep 3

	qemu-system-x86_64 \
	    -m 1024M \
	    -smp 4 \
	    -kernel $BZ_IMAGE \
        -hda $IMG_PATH \
        -drive file=$IMG_PATH,if=none,id=drive-virtio-disk1,format=raw,cache=none \
        -device virtio-blk-pci,scsi=off,config-wce=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk1,bootindex=1 \
        -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device virtio-net-pci,netdev=user.0 \
	    -serial mon:stdio -nographic \
	    -append "init=/linuxrc root=/dev/vda rootfstype=ext4 console=ttyS0 debug"
}


pre_clean_up
create_rootfs_img
start_vm

