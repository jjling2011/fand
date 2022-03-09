 根据CPU温度，通过GPIO控制树莓派风扇开关的小程序。  

#### 使用说明
fand分为服务器和客户端两种运行模式。服务器模式用于自动监视CPU温度通过GPIO发送控制信号。客户端模式在服务端运行后才可以使用。  

```bash
# 服务端需要root权限  
# 45度时关闭风扇，60度时开启风扇，每30秒测一次温度  
sudo fand serv 45 60 30
  
# 客户端  
fand [show | mon | on | off | high 60 | low 45]  
```

#### 编译及安装
```bash
# 编译
cargo build --release

# 安装
sudo cp ./target/release/fand /usr/local/bin
```

#### 电路图  
  
![电路示意图](https://github.com/jjling2011/fand/blob/rust/readme/circuit01.png?raw=true)  
*GPIO_wPi_3 物理编号15* 即 BCM22  
*GND 为任意0v插针*  
*5v为任意5v供电针（物理编号2或4)*  
