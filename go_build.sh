#!/bin/sh
#ref:https://www.atatech.org/articles/91600
#ref:http://www.cnblogs.com/muahao/p/7803844.html

# 1. 一键部署kernel开发环境
#        1.1 git clone linux qemu buildroot
#        1.2 分别configure , make -j 20
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
#   alikernel/

#cmd_qemu_system=`find . -name qemu-system-x86_64`
cmd_qemu_system="./open_linux/qemu/x86_64-softmmu/qemu-system-x86_64"
#cmd_qemu_img=`find . -name qemu-img`
cmd_qemu_img="./open_linux/qemu/qemu-img"
#iso_path=`find . -name Fedora-Server-dvd-x86_64-25-1.3.iso`
gitinfo="
git clone https://github.com/torvalds/linux.git\n
git clone https://github.com/buildroot/buildroot\n
git clone git://git.qemu-project.org/qemu.git\n
git clone git@gitlab.alibaba-inc.com:alikernel/kernel-4.9.git\n
git clone https://github.com/muahao/muahao_tools.git\n
wget http://busybox.net/downloads/busybox-1.27.2.tar.bz2\n"

root_dir=`cd "$(dirname "$0")";pwd`

#root dir
if [[ $root_dir != "/data/sandbox" ]];then
        echo "Please at root dir /data/sandbox, now we are at:`pwd`"
fi

root_dir="/data/sandbox/"
open_linux_dir="${root_dir}/open_linux"
buildroot_dir="${open_linux_dir}/buildroot/"
linux_dir="${open_linux_dir}/linux/"
qemu_dir="${open_linux_dir}/qemu/"
alikernel4_9_dir="${root_dir}/alikernel-4.9/"
busybox_dir="${open_linux_dir}/busybox-1.27.2/"
vm_path="${root_dir}/vm/"

cd $root_dir
#####################环境检查：
prepare(){
        if [[ ! -e ${cmd_qemu_system} || ! -e ${cmd_qemu_img} ]];then
                echo "$cmd_qemu_system not exist!"
                exit 1
        else
                echo "$cmd_qemu_system ok!"
        fi

        pwd_dir=`pwd`
        if [[ "$pwd_dir" != "/data/sandbox" ]];then
                echo "$pwd_dir != /data/sandbox"
                exit 1
        else
                echo "$pwd_dir is at right dir:/data/sandbox  ok!"
        fi

		if [[ ! -d "${vm_path}" ]];then
			mkdir -p "${vm_path}"
		fi
}


###################预备编译工作：
configure_buildroot(){
        cd $root_dir
        git clone https://github.com/muahao/muahao_tools.git
        cp "$root_dir/muahao_tools/example_config/gavins_config_for_buildroot" "$buildroot_dir/.config"
        git clone https://github.com/buildroot/buildroot
        yum install -y perl-ExtUtils-MakeMaker
        cd $buildroot_dir
        make -j 20
}

configure_linux(){
        cd $root_dir
        cp "$root_dir/muahao_tools/example_config/gavins_config_for_linux" "$linux_dir/.config"
        git clone https://github.com/torvalds/linux.git
        cd $linux_dir
        make -j 20
}

configure_qemu() {
    #只要编译qemu的时候需要用
        cd $open_linux_dir
        git clone git://git.qemu-project.org/qemu.git
        cd $qemu_dir
        yum install pixman-devel -y
        yum install -y glib2-devel
   ./configure --target-list=x86_64-softmmu \
               --enable-debug --enable-werror \
               --disable-fdt --disable-kvm \
               --disable-xen --disable-vnc
	   make -j 20
}

configure_busybox(){
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

configure_one(){
        if [[ $1 == "buildroot" ]];then
                configure_buildroot
        elif [[ $1 == "linux" ]];then
                configure_linux
        elif [[ $1 == "qemu" ]];then
                configure_qemu
        elif [[ $1 == "busybox" ]];then
                configure_busybox
        else
                echo "configure lack argument!"
        fi
}

one_deply(){
        if [[ ! -e $open_linux_dir ]];then
                mkdir -p $open_linux_dir
                configure_qemu
                configure_buildroot
                configure_linux
        else
                echo "$open_linux_dir already exist!"
                exit 0
        fi
}

####################方法1：
creat_image_01(){
        #方法1: 仅仅需要 ${cmd_qemu_img} create -f raw ${img_name} 10G
        #${cmd_qemu_img} create -f qcow2 ${img_name} 20G
        if [[ -e ${img_name} ]];then
                rm -fr ${img_name}
        fi
        ${cmd_qemu_img} create -f raw ${img_name} 10G
}

start_vm_01(){
   ${cmd_qemu_system} \
   -machine type=q35 -serial mon:stdio -nographic \
   -kernel $kernel_bzImage \
   -append "earlyprintk=ttyS0 console=ttyS0 debug" \
   -hda ${img_name}
}

stop_vm_01() {
   killall qemu-system-x86_64
}


###################方法2：
creat_image_02(){
        #方法2: 需要创建文件系统
    if [[ -e ${img_name} ]];then
        rm -fr ${img_name}
    fi
    ${cmd_qemu_img} create -f raw ${img_name} 10G
	if [[ $? != 0 ]];then
		echo "${cmd_qemu_img} create -f raw ${img_name} 10G failed!"
		exit 1
	fi
    mkfs -t ext4 ${img_name}
    if [[ -e ${mount_point} ]];then
        umount ${mount_point}
        rm -fr ${mount_point}
    fi
    mkdir -p ${mount_point}
    mount -o loop ${img_name} ${mount_point}
}

modules_install_02(){
        cd $module_path;
		make modules_install INSTALL_MOD_PATH=$mount_point
}

boot_02(){
${cmd_qemu_system} \
        -m 4096M \
        -smp 4 \
		-serial mon:stdio -nographic \
		-kernel $kernel_bzImage \
        -append "init=/linuxrc root=/dev/sda earlyprintk=ttyS0 console=ttyS0 debug" \
        -drive format=raw,file=${img_name}

#    -append "console=ttyS0" \
#       -hda ./${img_name}
}

kill_02(){
        ps axu | grep qemu-system-x86_64 |grep -v grep | awk '{print $2}' | xargs kill -9
}


#############help
if [[ $# == 0 ]];then
        echo "一键部署:./$0 one_deploy"
        echo "编译:./$0 configure buildroot/linux/qemu/busybox"
        echo "环境检查:./$0 prepare"
        echo ""
		echo "方法1.step1:./$0 creat_image /data/sandbox/vm/disk01.raw(device)"
        echo "方法1.step2:./$0 start_vm /xx/xx/bzImage /data/sandbox/vm/disk01.raw"
        echo "方法1.step3:./$0 stop_vm"
        echo ""
		echo "方法2.with busybox:"
		echo "方法2.step1:./$0 mkfs /data/sandbox/vm/Disk01.raw(device) /data/sandbox/vm/Img01(mountpoint)"
        echo "方法2.step2:./$0 modules_install /data/sandbox/alikernel-4.9/kernel-4.9/ /data/sandbox/vm/Img01/"
        echo "方法2.step3:./$0 busybox_boot /xx/xx/bzImage /data/sandbox/vm/Disk01.raw"
        echo "方法2.step4:./$0 kill"
        echo ""
        echo "bzImage列表:"
        echo `find . -name bzImage`
        echo ""
        echo -e "Git信息:\n`echo -e $gitinfo`-e "
        echo ""

else
        #检查环境
        prepare

        #一键部署
        if [[ $1 == "one_deploy" ]];then
                one_deploy
        fi

        #预备：编译qemu
        if [[ $1 == "configure" ]];then
                configure_target=$2
                configure_one $configure_target
        #方法1：
        elif [[ $1 == "creat_image" ]];then
                img_name="$2"
                creat_image_01 $img_name
        elif [[ $1 == "start_vm" ]];then
                kernel_bzImage="$2"
				img_name="$3"
                start_vm_01
        elif [[ $1 == "stop_vm" ]];then
                stop_vm_01
        #方法2：
        elif [[ $1 == "mkfs" ]];then
                echo "Begin mkfs..."
				img_name=$2
				mount_point=$3
				if [[ -z  $img_name || -z $mount_point ]];then
					echo "img_name:$img_name , mount_point:$mount_point"
					exit 1
				else
                	creat_image_02 $img_name $mount_point
				fi
        elif [[ $1 == "modules_install" ]];then
				module_path=$2
				mount_point=$3
				if [[ -z $module_path || -z $mount_point ]];then
					echo "module_path:$module_path is empty!"
					exit 1
				else
                	modules_install_02 $module_path $mount_point
				fi
        elif [[ $1 == "busybox_boot" ]];then
                kernel_bzImage="$2"
				img_name="$3"
                boot_02 $kernel_bzImage $img_name
        elif [[ $1 == "kill" ]];then
                kill_02
        fi
fi
