fand是根据CPU温度，通过GPIO控制树莓派风扇开关的小程序。
  
##### 使用说明
fand分为服务器和客户端两种运行模式。服务器模式用于自动监视CPU温度通过GPIO #22针脚发送控制信号。客户端模式在服务端运行后才可以使用。  
```bash
#启动服务器模式需要root权限
sudo ./fand -m s

#客户端模式不需要权限
./fand
```
  
##### 编译
```bash
#安装编译工具
#安装zig v0.11.0，其他版本不一定能成功编译
sudo pacman -S base-devel autoconf-archive zig

#编译安装libgpiod v1.6.4
wget https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/snapshot/libgpiod-1.6.4.tar.gz
tar -xvf ./libgpiod-1.6.4.tar.gz
cd libgpiod-1.6.4
mkdir /tmp/libgpiod
./autogen.sh --prefix=/tmp/libgpiod
make
make install

#clone代码并编译
git clone https://github.com/jjling2011/fand
cd fand
zig build

#查看结果
./zig-out/bin/fand --help

#(可选)清理无用文件
rm -rf /tmp/libgpiod
sudo pacman -Rsc base-devel autoconf-archive zig
```
  
##### 电路图
![电路图](https://raw.githubusercontent.com/jjling2011/fand/rust/readme/circuit01.png)  
GPIO_wPi_3 物理编号15 即 BCM GPIO #22  
GND 为任意0v插针  
5v为任意5v供电针（物理编号2或4)  
  
##### Credits
[https://github.com/MasterQ32/zig-args](https://github.com/MasterQ32/zig-args)  
[https://github.com/frmdstryr/zig-datetime](https://github.com/frmdstryr/zig-datetime)  
