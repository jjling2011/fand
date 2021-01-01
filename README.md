 根据CPU温度，通过GPIO控制树莓派风扇的开关的小程序。  

#### 使用说明
fand分为服务器和客户端两种运行模式。服务器模式用于监视CPU温度及自动通过GPIO发送控制信号。服务端运行后才可以使用客户端模式。客户端模通过GRPC向服务端发送控制命令，用于查看及临时改变风扇运行状态。

```bash
# 服务端需要root权限  
sudo fand -server [-hi 启动温度 | -low 停止温度 | -pin 控制针BCM编号 | -port GRPC端口号]  
  
# 客户端  
fand [-on | -off | -m]  
```

#### 编译及安装
安装好Golang及确保网络畅通后执行以下命令
```bash
# 编译
go build fand.go

# 安装
sudo cp ./fand /usr/local/bin
```

#### 电路图  
  
![电路示意图](https://raw.githubusercontent.com/jjling2011/rfan/master/readme/circuit01.png)  
*GPIO_wPi_3 物理编号15* 即 BCM22  
*GND 为任意0v插针*  
*5v为任意5v供电针（物理编号2或4)*  