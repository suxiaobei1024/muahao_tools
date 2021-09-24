yum groups mark install "Development Tools"
yum groups mark convert "Development Tools"
yum groupinstall "Development Tools" -y
yum install pixman-devel -y
yum install -y glib2-devel
#安装ncurse-devel包 （make menuconfig 文本界面窗口依赖包）
yum -y install ncurses-devel
yum install automake autoconf libtool bison flex cmake crash gcc make ncurses ncurses-devel perl -y

yum install -y perl-ExtUtils-MakeMaker

yum install -y ctags cscope

yum -y install gcc+ gcc-c++

yum install kernel-devel -y

yum install -y elfutils-libelf-devel 
yum install -y openssl-devel
yum install glibc-static -y
yum install -y qemu
yum install seabios-bin -y
#yum update -y
