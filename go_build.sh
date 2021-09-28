#!/bin/sh
#ref:https://www.atatech.org/articles/91600
#ref:http://www.cnblogs.com/muahao/p/7803844.html

# 1. 一键部署kernel开发环境
#        1.1 git clone linux qemu buildroot
#        1.2 分别configure , make -j 20
#
# 2. 提供2个方法快速启动vm:
#       方法1：（函数名01结尾） 推荐这个方法！简单！gavin的方式！
                # qemu + buildroot + kernel
#       方法2： （函数名02结尾）
                # qemu + kernel
#目录结构:
#root path:/data/sandbox
#tree
#   open_linux/
#       buildroot/
#       linux/
#       qemu/
#   sPkernel/


gitinfo="
git clone https://github.com/torvalds/linux.git\n
git clone https://github.com/buildroot/buildroot\n
git clone git://git.qemu-project.org/qemu.git\n
git clone git@gitlab.alibaba-inc.com:alikernel/kernel-4.9.git\n
git clone https://github.com/muahao/muahao_tools.git\n
wget http://busybox.net/downloads/busybox-1.27.2.tar.bz2\n"

###############################
#    ENV                      #
###############################
root_dir="/data/sandbox/"
open_linux_dir="${root_dir}/open_linux"
buildroot_dir="${open_linux_dir}/buildroot/"
linux_dir="${open_linux_dir}/linux/"
qemu_dir="${open_linux_dir}/qemu/"
muahao_tools_dir="${root_dir}/muahao_tools/"
busybox_dir=`ls -d  /data/sandbox/open_linux/busybox*  | grep -v tar`
vm_path="${root_dir}/vm/"
rootfs_cpio_path="${buildroot_dir}output/images/rootfs.cpio.xz"
cmd_qemu_system=`which qemu-system-x86_64`
#test ! -e "${qemu_dir}/x86_64-softmmu/qemu-system-x86_64" && cmd_qemu_system=`which qemu-system-x86_64`
cmd_qemu_img="${qemu_dir}/qemu-img"
test ! -e "${qemu_dir}/qemu-img" && cmd_qemu_img=`which qemu-img`

###############################
#       .config               #
###############################
#.config
gavins_config_for_linux_path="${muahao_tools_dir}/example_config/kernel_config/gavins_config_for_linux"
gavins_config_for_buildroot_path="${muahao_tools_dir}/example_config/buildroot_config/gavins_config_for_buildroot"
#目标.config
config_for_linux_path_we_need=$gavins_config_for_linux_path
config_for_buildroot_path_we_need=$gavins_config_for_buildroot_path

. ${muahao_tools_dir}/shell_libs/log.sh

cd $root_dir
check(){
	#check buildroot
	log_info "Check...."
	if [[ ! -e ${rootfs_cpio_path} ]];then
		log_info "${rootfs_cpio_path} not exist!"
	else
		log_info "${rootfs_cpio_path} exist!"
	fi

	#check qemu
    if [[ ! -e ${cmd_qemu_system} || ! -e ${cmd_qemu_img} ]];then
		log_error "$cmd_qemu_system not exist!"
    else
		log_info "$cmd_qemu_system exist!"
    fi

	#check vm
	if [[ ! -d "${vm_path}" ]];then
		mkdir -p "${vm_path}"
		log_info "Create dir ${vm_path}"
	else
		log_info "${vm_path} already exist!"
	fi

	#check linux .config
	if [[ $(cat ${linux_dir}/.config | grep "CONFIG_INITRAMFS_SOURCE" | grep -q "open_linux";echo $?) != 0 ]];then
		log_info "linux .config CONFIG_INITRAMFS_SOURCE not configure, try to fix..."
		aa="CONFIG_INITRAMFS_SOURCE=${rootfs_cpio_path}"
		sed -i '/CONFIG_INITRAMFS_SOURCE/d' "${linux_dir}/.config"
		echo $aa >> "${linux_dir}/.config"
		loginfo "fix done!"
	else
		log_info "linux .config CONFIG_INITRAMFS_SOURCE already configured!"
	fi
}


###################预备编译工作：
build_buildroot(){
	echo "We suggest to use gavin's .config to build buildroot..."
	if [[ ! -e ${config_for_buildroot_path_we_need} ]];then
		log_error_exit "${config_for_buildroot_path_we_need} not exist!"
	else
		log_info "We are going to use ${config_for_buildroot_path_we_need} "
	fi

	dd=`date +%Y%m%d-%H%M%S`
	if [[ $(mv "$buildroot_dir/.config" "/tmp/buildroot_config_${dd}" >/dev/null 2>&1;echo $?) == 0 ]];then
		log_info "Backup: $buildroot_dir/.config -> /tmp/buildroot_config_$dd success!"
	else
	#	log_error_exit "Backup: $buildroot_dir/.config -> /tmp/buildroot_config_$dd failed!"
		log_info "Backup: $buildroot_dir/.config -> /tmp/buildroot_config_$dd failed!"
	fi

	# begin build buildroot
    cd $root_dir
	if [[  ! -e ${muahao_tools_dir} ]];then
    	git clone https://github.com/muahao/muahao_tools.git
		if [[ $? != 0 ]];then
			log_error_exit "git clone https://github.com/muahao/muahao_tools.git failed!"
		fi
	else
		log_info "muahao_tools.git exist!"
	fi

    cp "${config_for_buildroot_path_we_need}" "$buildroot_dir/.config"
	if [[ ! -e ${buildroot_dir} ]];then
		git clone https://github.com/buildroot/buildroot
	else
		log_info "https://github.com/buildroot/buildroot already clone !"
	fi

	#if [[ $(yum install -y perl-ExtUtils-MakeMaker >/dev/null 2>&1;echo $?) != 0 ]];then
	#if [[ $(yum install -y perl-ExtUtils-MakeMaker;echo $?) != 0 ]];then
	#	log_error_exit "yum install -y perl-ExtUtils-MakeMaker failed"
	#fi

    cd $buildroot_dir
	log_info  "begin to build buildroot"
    make -j 20
}

configure_linux(){
	# define .config
	log_info "begin to configure liux"
	log_info "We suggest to use gavin's .config to build linux..."
	if [[ ! -e ${config_for_linux_path_we_need} ]];then
		log_error_exit "${config_for_linux_path_we_need} not exist!"
	else
		log_info "We are going to use ${config_for_linux_path_we_need} "
	fi

	dd=`date +%Y%m%d-%H%M%S`
	if [[ $(mv "$linux_dir/.config" "/tmp/config_${dd}" >/dev/null 2>&1;echo $?) == 0 ]];then
		log_info "Backup: $linux_dir/.config -> /tmp/config_$dd success!"
	else
		#log_error_exit "Backup: $linux_dir/.config -> /tmp/config_$dd failed!"
		log_info "Backup: $linux_dir/.config -> /tmp/config_$dd failed!"
	fi

	if [[ $(cp "${config_for_linux_path_we_need}" "$linux_dir/.config" >/dev/null 2>&1;echo $?) == 0  ]];then
		log_info "We final used .config is: ${config_for_linux_path_we_need}"
	else
		log_error_exit "We final used .config is: ${config_for_linux_path_we_need}"
	fi

	# should modify .config
	if [[ $(cat ${linux_dir}/.config | grep "CONFIG_INITRAMFS_SOURCE" | grep -q "open_linux";echo $?) != 0 ]];then
		log_error_exit "${linux_dir}/.config CONFIG_INITRAMFS_SOURCE not configure!"
		aa="CONFIG_INITRAMFS_SOURCE=${rootfs_cpio_path}"
		sed -i '/CONFIG_INITRAMFS_SOURCE/d' "${linux_dir}/.config"
		echo $aa >> "${linux_dir}/.config"
	else
		log_info "`cat ${linux_dir}/.config | grep 'CONFIG_INITRAMFS_SOURCE' | grep -v grep`"
	fi

	# begin build linux
    cd $root_dir
	if [[ ! -e ${root_dir} ]];then
		log_info "We should do: git clone https://github.com/torvalds/linux.git ..."
        git clone https://github.com/torvalds/linux.git
	else
		log_info "$linux_dir already exist! Please cd $linux_dir to excute git pull !"
	fi
	log_info "Begin configure linux..."
    cd $linux_dir
    make -j 20
}

build_qemu() {
    #只要编译qemu的时候需要用
    cd $open_linux_dir
    git clone git://git.qemu-project.org/qemu.git
 	cd $qemu_dir
    if [[ $(yum install pixman-devel -y >/dev/null 2>&1;echo $?) != 0 ]];then
    	log_error_exit "yum install pixman-devel -y failed"
    fi
    if [[ $(yum install -y glib2-devel >/dev/null 2>&1;echo $?) != 0 ]];then
    	log_error_exit "yum install pixman-devel -y failed"
    fi
    ./configure --target-list=x86_64-softmmu \
       --enable-debug --enable-werror \
       --disable-fdt --disable-kvm \
       --disable-xen --disable-vnc
	make -j 20
}

build_busybox(){
	cd $open_linux_dir
	wget http://busybox.net/downloads/busybox-1.27.2.tar.bz2
	tar  -xjf busybox-1.27.2.tar.bz2
	yum install glibc-static -y
	cd $busybox_dir
	make defconfig
	make menuconfig
	#这里有一个重要的配置，因为 busybox 将被用作 init 程序，而且我们的磁盘镜像中没有任何其它库，所以 busybox 需要被静态编译成一个独立、无依赖的可执行文件，以免运行时发生链接错误:
	#Busybox Settings ---> Build Options ->[*] Build BusyBox as a static binary (no shared libs)
	make -j 20
	#编译完成后在当前目录下可以看到 busybox 可执行文件，查看大小才 2.5M 左右。整个 busybox 套件只有这一个可执行文件，里面包含了若干工具。比如：
	make CONFIG_PREFIX=${mount_point_path}  install
	####like this:
	##make CONFIG_PREFIX=/data/sandbox/img  install
	#/data/sandbox/img//bin/ash -> busybox
    #/data/sandbox/img//bin/base64 -> busybox
    #/data/sandbox/img//bin/cat -> busybox
    #/data/sandbox/img//bin/chattr -> busybox
}

build_kernel() {
	kernel_source_path=$1
    loginfo "编译内核:" "$kernel_source_path"
	cd $kernel_source_path
	make -j 20
}

build_one_project(){
    if [[ $1 == "buildroot" ]];then
            build_buildroot
    elif [[ $1 == "linux" ]];then
            configure_linux
    elif [[ $1 == "kernel" ]];then
			kernel_source_path=$2
            build_kernel $kernel_source_path
    elif [[ $1 == "qemu" ]];then
            build_qemu
    elif [[ $1 == "busybox" ]];then
            build_busybox
    else
            echo "configure lack argument!"
    fi
}

one_deply(){
    if [[ ! -e $open_linux_dir ]];then
            mkdir -p $open_linux_dir
            build_qemu
            build_buildroot
            configure_linux
    else
            echo "$open_linux_dir already exist!"
            exit 0
    fi
}

####################方法1：
create_image_01() {
	rootfs_id=$1
	image_name="${rootfs_id}.raw"
	image_path="${vm_path}/${rootfs_id}.raw"
	image_mountpoint="${vm_path}/${rootfs_id}"
	
	# Pre clean
	test -d $image_mountpoint && umount $image_mountpoint
	test ! -d $image_mountpoint && mkdir -p $image_mountpoint
	
	# Create a raw
    ${cmd_qemu_img} create -f raw ${img_name} 10G
	mount -t ext4 -o loop ${image_path} ${image_mountpoint}

	# Pack rootfs img
	configure_rootfs_img $rootfs_id


	log_info "succeed to create rootfs, image_path:$image_path, image_mountpoint:$image_mountpoint"
}

configure_rootfs_img() {
    rootfs_id=$1
    image_name="${rootfs_id}.raw"
    image_path="${vm_path}/${rootfs_id}.raw"
    image_mountpoint="${vm_path}/${rootfs_id}"

	# 1. install busybox in rootfs
	cd $busybox_dir
	sudo make  CONFIG_PREFIX=$image_mountpoint install

	# 2. install_modules
	# install_modules

	# 4 rootfs 
	cd $image_mountpoint
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


start_vm_01() {
	# 6 start qemu
	bzImage_path=$1
	img_path=$2

	loginfo "bzImage_path:" "$bzImage_path"
	loginfo "img_path:" "$img_path"

	sleep 1
	${cmd_qemu_system} \
	    -m 4096M \
	    -smp 4 \
	    -kernel $bzImage_path \
        -hda $img_path \
        -drive file=$img_path,if=none,id=drive-virtio-disk1,format=raw,cache=none \
        -device virtio-blk-pci,scsi=off,config-wce=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk1,bootindex=1 \
        -netdev "user,id=user.0,hostfwd=tcp:0.0.0.0:2222-:22" -device virtio-net-pci,netdev=user.0 \
	    -serial mon:stdio -nographic \
	    -append "init=/linuxrc root=/dev/vda rootfstype=ext4 console=ttyS0 debug"
}

stop_vm_01() {
    killall qemu-system-x86_64
}


do_kernel_modules_install(){
	kernel_code_path=$1
	img_mountpoint=$2

	loginfo "kernel_code_path:" "$kernel_code_path"
	loginfo "img_mountpoint:" "$img_mountpoint"
	sleep 2

    cd $kernel_code_path;
	make modules_install INSTALL_MOD_PATH=$img_mountpoint
}

do_boot_via_initramfs(){
bzImage_path=$1
initramfs_path=$2

loginfo "bzImage_path:" "$bzImage_path"
loginfo "initramfs_path:" "$initramfs_pathh"

${cmd_qemu_system} \
        -m 4096M \
        -smp 4 \
        -kernel $bzImage_path \
        -initrd $initramfs_path \
        -serial mon:stdio -nographic \
        -append "init=/linuxrc root=/dev/sda console=ttyS0 debug"
}

kill_02(){
        ps axu | grep qemu-system-x86_64 |grep -v grep | awk '{print $2}' | xargs kill -9
}


usage() {
    loginfo "一键部署" "$0 one_deploy"
    loginfo "环境" "$0 env-install"
    #loginfo "编译" "$0 build  buildroot"
    #loginfo "编译" "$0 build  linux"
    loginfo "编译" "$0 build  kernel /data/sandbox/linux-5.4.147/"
    #loginfo "编译" "$0 build  qemu"
    loginfo "编译" "$0 build  busybox"
    loginfo "环境检查" "$0 check"

    echo ""
	loginfo "方法1.step1" "$0 create_rootfs rootfs-01"
    loginfo "方法1.step2" "$0 modules_install /data/sandbox/linux-5.4.147/ /data/sandbox/vm/rootfs-01/"
    loginfo "方法1.step3" "$0 start_vm /xx/xx/bzImage /data/sandbox/vm/rootfs-01.raw"
    loginfo "方法1.step4" "$0 stop_vm"

    #loginfo "方法2.step3" "$0 busybox_boot /xx/xx/bzImage /data/sandbox/vm/Disk01.raw"
    #loginfo "方法2.step4" "$0 kill"

    echo ""
    loginfo "方法3.with busybox+initramfs:"
    loginfo "方法3.step1" "$0 create_initramfs \$seq \$kernel_path"
    loginfo "           " "\t$0 create_initramfs 01 /data/sandbox/linux-5.4.147"
    loginfo "方法3.step3" "$0 busybox_boot_via_initramfs \$bzImage \$initramfs_path"
    loginfo "           " "\t$0 busybox_boot_via_initramfs /xx/xx/bzImage /data/sandbox/initramfs-01.cpio.gz"
    loginfo "方法3.step4" "$0 kill"


    echo ""
    loginfo "bzImage列表:"
    find ${root_dir} -name "*bzImage"

    echo ""
    loginfo "initramfs列表:"
	find ${root_dir} -name "*.cpio.gz"

    echo ""
    loginfo "rootfs列表:"
	find ${vm_path} -name "root*.raw"

	#echo ""
    #loginfo "Git信息"
	#echo "`echo -e $gitinfo` "
    #echo ""
}

do_env_install() {
	echo "bash /data/sandbox/muahao_tools/install_os_kernel_depennd_packages.sh"
	bash /data/sandbox/muahao_tools/install_os_kernel_depennd_packages.sh
}


create_initramfs() {
	seq=$1
	kernel_source_path=$2
	bash /data/sandbox/muahao_tools/create_initramfs.sh  01_create_initramfs $seq $kernel_source_path
}


if [[ $# == 0 ]];then
	usage
else
    #检查环境
    check

    #一键部署
    if [[ $1 == "one_deploy" ]];then
		one_deploy
    fi

    #预备：编译qemu
    if [[ $1 == "build" ]];then
        project_name=$2
        kernel_source_path=$3
        build_one_project $project_name $kernel_source_path
    #########################
    #       方法1           #
    #########################
    elif [[ $1 == "create_rootfs" ]];then
        rootfs_id="$2"
        create_image_01 $rootfs_id
    elif [[ $1 == "modules_install" ]];then
		kernel_code_path=$2
		img_mountpoint=$3

		test ! -e $kernel_code_path && echo "kernel_code_path is empty" && exit 0
		test ! -e $img_mountpoint && echo "img_mountpoint is empty" && exit 0
	
        do_kernel_modules_install $kernel_code_path $img_mountpoint
    elif [[ $1 == "start_vm" ]];then
        bzImage_path="$2"
		img_path="$3"
        start_vm_01 $bzImage_path $img_path
    elif [[ $1 == "stop_vm" ]];then
        stop_vm_01
    elif [[ $1 == "env-install" ]];then
        do_env_install

    #########################
    #       方法3：         #
    #########################
    elif [[ $1 == "create_initramfs" ]];then
		seq=$2
		source_path=$3
		create_initramfs $seq $source_path
    elif [[ $1 == "busybox_boot_via_initramfs" ]];then
        bzImage_path="$2"
		init_ramfs_path="$3"
        do_boot_via_initramfs $bzImage_path $init_ramfs_path
    elif [[ $1 == "kill" ]];then
        kill_02
    fi
fi
