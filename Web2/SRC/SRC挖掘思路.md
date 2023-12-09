学习公开分享的挖掘思路

```txt
youtube、公众号、B站 ——》 SRC挖掘
hackeone		   ——》 漏洞披露
```

SRC 挖掘= 信息收集+逻辑漏洞（功能点的挖掘）

信息收集

拿到xxx.com

第一件事是收集子域名 *.xxx.com

```solidity
xray subdomian --target xxx.com --html-output xxx.html
```

第二步 dirsearch 收集敏感目录或文件

前端js api appid secret

后端：逻辑漏洞（功能点）