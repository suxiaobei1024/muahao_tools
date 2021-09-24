yum groups mark install "Development Tools"
yum groups mark convert "Development Tools"
yum groupinstall "Development Tools" -y
yum install pixman-devel -y
yum install -y glib2-devel
#安装ncurse-devel包 （make menuconfig 文本界面窗口依赖包）
yum -y install ncurses-devel
yum install automake autoconf libtool bison flex cmake crash -y

yum install -y perl-ExtUtils-MakeMaker

yum install -y ctags cscope

yum -y install gcc+ gcc-c++
