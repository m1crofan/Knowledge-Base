### 外网

一开始琢磨的是在Ubuntu上使用clash上外网，发现行不通；于是乎转向研究虚拟机走主机的代理。

使用NAT模式，或桥接模式；先保证虚拟机能够上网

![image-20240109211029885](https://raw.githubusercontent.com/m1crofan/image/main/image-20240109211029885.png)

之后在主机使用ipconfig命令查看能上网的ip是啥

![image-20240109211126883](https://raw.githubusercontent.com/m1crofan/image/main/image-20240109211126883.png)

![image-20240109211108916](https://raw.githubusercontent.com/m1crofan/image/main/image-20240109211108916.png)

这里有个坑，主机笔记本使用wifi上网；有两块无线网卡 我该相信哪块呢？

- 方法1：用虚拟机ping一下 哪个能通
- 方法2：有网关的能上网

查看到了主机的IP之后，ubuntu设置代理

关闭主机的局域网防火墙

设置主机代理允许局域网访问

设置clash软件内的选项：允许局域网访问

![image-20240109211345249](https://raw.githubusercontent.com/m1crofan/image/main/image-20240109211345385.png)

注意，这里只需要设置socks就好了。

成功访问Google

![image-20240109211432628](https://raw.githubusercontent.com/m1crofan/image/main/image-20240109211432628.png)