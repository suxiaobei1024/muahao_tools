#!/bin/bash

#qemu-system-x86_64 \
#    -m 512M \
#    -smp 4 \
#    -serial mon:stdio -nographic -s \
#    -kernel /usr/src/linux-5.4.143/arch/x86_64/boot/bzImage \
#    -drive format=raw,file=./disk.raw \
#    -append "earlyprintk=ttyS0 console=ttyS0 debug" \
#    -append "init=/linuxrc root=/dev/sda"
#

#qemu-system-x86_64 \
#    -m 512M \
#    -smp 4 \
#    -serial mon:stdio -nographic \
#    -kernel /usr/src/linux-5.4.143/arch/x86_64/boot/bzImage \
#    -initrd /data/sandbox/busybox-1.21.0/_install/rootfs.img.gz
#    -drive format=raw,file=./disk.raw \
#    -append "init=sbin/init root=/dev/sda"

	#-initrd /data/sandbox/busybox-1.21.0/_install/rootfs.img.gz \
	#-initrd /boot/initramfs-5.4.143ahao.mu.test.img \
	#-nographic -enable-vnc \

	#-append "init=sbin/init root=/dev/sda rootfstype=ext4 rw console=ttyS0" --enable-kvm


03_start_kernel() {
	action=$1
	vmId=$2
	my_BzImage=$3
	my_initrd=$4

	#my_BzImage="/usr/src/linux-5.4.147/arch/x86_64/boot/bzImage"
	#my_hdd="/data/sandbox/img/disk1.raw"
		#-drive format=raw,file=./img/disk1.raw \
        #-hda $my_hdd \
	#my_initrd="/boot/initramfs-5.4.147.ahao.mu.img"
        #-drive format=raw,file=/data/sandbox/rootfs.img \
	#my_initrd="./initramfs.cpio.gz"
	my_initrd="/tmp/initramfs-busybox-x86.cpio.gz"
	qemu-system-x86_64 \
		-m 1024M \
		-smp 4 \
		-kernel $my_BzImage \
        -initrd $my_initrd \
        -drive format=raw,file=/data/sandbox/rootfs.img \
        -serial mon:stdio -nographic \
		-append "init=/linuxrc root=/dev/sda console=ttyS0 debug"
}


		#-append "init=/linuxrc root=/dev/sda earlyprintk=ttyS0 console=ttyS0 debug"
#03_start_kernel() {
#    action=$1
#    vmId=$2
#    my_BzImage=$3
#    my_initrd=$4
#
#    #my_BzImage="/usr/src/linux-5.4.147/arch/x86_64/boot/bzImage"
#    #my_hdd="/data/sandbox/img/disk1.raw"
#        #-drive format=raw,file=./img/disk1.raw \
#        #-hda $my_hdd \
#    #my_initrd="/boot/initramfs-5.4.147.ahao.mu.img"
#    my_initrd=."/initramfs.cpio.gz"
#    qemu-system-x86_64 \
#        -m 1024M \
#        -smp 4 \
#        -s \
#        -kernel $my_BzImage \
#        -serial mon:stdio -nographic \
#        -initrd $my_initrd \
#        -drive format=raw,file=./img/disk1.raw \
#        -append "init=/linuxrc root=/dev/sda earlyprintk=ttyS0 console=ttyS0 debug"
#}



#04_start_kernel() {
#    action=$1
#    vmId=$2
#    my_BzImage=$3
#    my_initrd=$4
#
#    #my_BzImage="/usr/src/linux-5.4.147/arch/x86_64/boot/bzImage"
#    my_initrd="/data/sandbox/initramfs.cpio.gz"
#        #-drive format=raw,file=./img/disk1.raw \
#    #my_initrd="/boot/initramfs-5.4.147.ahao.mu.img"
#    qemu-system-x86_64 \
#        -m 1024M \
#        -smp 4 \
#        -s \
#        -kernel $my_BzImage \
#        -initrd $my_initrd \
#        -nographic \
#        -append "init=sbin/init root=/dev/sda console=ttyS0"
#}

01_create_disk() {
	action=$1
	seq=$2
	
	test -e server$seq && echo "already exist path:server$seq, exit" && exit 0

	mkdir server$seq
	qemu-img create -f raw ./img/disk${seq}.raw 8192M
	mkfs -t ext4 ./img/disk${seq}.raw
	mount -o loop ./img/disk${seq}.raw ./server$seq
}

main() {
	action=$1

	if [[ $action == "01_create_disk" ]];then
		01_create_disk $* 
	elif [[ $action == "02_build_kernel" ]];then
		02_build_kernel $*
	elif [[ $action == "03_start_kernel" ]];then
		03_start_kernel $*
	else
		usage
	fi
}

usage() {
	echo "Usage:"
	echo "./$0"
	echo "      01_create_disk vmId"
	echo "      02_build_kernel vmId my_BzImage my_initrd"
	echo "      03_start_kernel vmId my_BzImage my_initrd"
	echo ""
	echo ""
	echo "Example:"
	echo "     ./$0 01_create_disk 1"
	echo "     ./$0 02_build_kernel kernelSourcePath"
	echo "     ./$0 03_start_kernel 1 /usr/src/linux-5.4.147/arch/x86_64/boot/bzImage /boot/initramfs-5.4.147.ahao.mu.img"
	#my_BzImage="/usr/src/linux-5.4.147/arch/x86_64/boot/bzImage"
	##my_initrd="/data/sandbox/initramfs.cpio.gz"
	#my_initrd="/boot/initramfs-5.4.147.ahao.mu.img"
}

main $*
