#!/bin/bash
# Refs: https://blog.csdn.net/think_ycx/article/details/80800614
# create initramfs.cpio.gz
#

INITRAMFS_ID="initramfs-01"
mkdir $INITRAMFS_ID

BUSYBOX_DIR="/data/sandbox/open_linux/busybox-1.21.0"
TARGET_NAME="/data/sandbox/$INITRAMFS_ID.cpio.gz"
INITRAMFS_DIR="/data/sandbox/$INITRAMFS_ID/"
KERNEL_SOURCE_DIR="/usr/src/linux-5.4.147/"
BZ_IMAGE="/usr/src/linux-5.4.147/arch/x86_64/boot/bzImage"

# 1. install busybox
#cd $BUSYBOX_DIR
#sudo make  CONFIG_PREFIX=$INITRAMFS_DIR install

# 2. install kernel modules in $INITRAMFS_ID
#cd $KERNEL_SOURCE_DIR
#sudo make modules_install \ # 安装内核模块
#INSTALL_MOD_PATH=$INITRAMFS_DIR  # 指定安装路径

# 4 rootfs mknod and create $INITRAMFS_ID.cpio.gz
cd $INITRAMFS_DIR
test ! -d proc && mkdir proc
test ! -d sys && mkdir sys
test ! -d dev && mkdir dev
test ! -d etc && mkdir etc
test ! -d tmp && mkdir tmp
test ! -d sys/kernel/debug && mkdir -p sys/kernel/debug
test ! -d etc/init.d && mkdir etc/init.d

#if [ ! -d proc ] && [ ! -d sys ] && [ ! -d dev ] && [ ! -d etc/init.d ]; then
#	mkdir proc sys dev etc etc/init.d
#fi

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
find . | cpio -o --format=newc > $TARGET_NAME

# 6 start qemu
qemu-system-x86_64 \
    -m 1024M \
    -smp 4 \
    -kernel $BZ_IMAGE \
    -initrd $TARGET_NAME \
    -serial mon:stdio -nographic \
    -append "init=/linuxrc root=/dev/sda console=ttyS0 debug"

#qemu-system-x86_64 -kernel $BZ_IMAGE  -initrd $TARGET_NAME   -append "console=ttyS0 ramdisk_size=409600 root=/dev/sda init=/linuxrc rw" -nographic
