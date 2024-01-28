### PHP Built-in Server

它是php自带的Web服务器，多用于在研发阶段快速启动并运行一个可以执行PHP脚本的Web服务器。由于其性能及安全性并没有得到完好的保障，所以PHP官方并不建议在生产环境下使用这个服务器。

有一个Bug存在于PHP Built-in Server中。PHP Built-in Server在解析TCP数据流时，对于两个HTTP请求，在第二次请求时，如果请求一个非PHP后缀的文件服务器会认为这是一个静态文件，所以将这个文件直接读取并返回。

但这个过程中存在一个逻辑问题，就是在解析第一个请求时遗留下来的client->request.path_translated没有被清理，而这个变量指向的就是第一个请求的文件绝对路径。

所以造成了一个Bug，如果外面发送以下数据包：

```http
GET /info.php HTTP/1.1
Host: 192.168.1.163:9090

GET /xxxxx.css HTTP/1.1
```

第一个请求指向是一个正常存在的PHP文件/info.php ,第二个请求指向的是一个不存在的静态文件/xxxxx.css。此时在解析第二个请求的时候，会读取到/info.php的文件内容，但又会按照静态文件的方式返回这个文件的源码，而不是使用PHP解释器进行解析。

导致攻击者可以通过这个trick下载到/info.php

版本要求小于：php：7.4.22 

参考链接：

[PHP Development Server <= 7.4.21 - 远程源代码泄漏 ](https://blog.projectdiscovery.io/php-http-server-source-disclosure/)

### PHP文件包含使用多级软链接绕过文件判断

这个trick最早的场景是，我们如何通过require_once来多次包含同一个文件。这个场景可以抽象为如下代码：

```php
<?php
require_once '/www/config.php';
// some logic here...
require_once $_GET['file'];
?>
```

就是在审计时找到一处文件包含漏洞（使用require_once或include_once），想要利用这个漏洞读取以下数据库配置文件之类的源码，通常可以使用`php://filter/convert.base64-encode/resource=file`这样的方式将文件以base64的形式读取出来。但是这个文件在前面已经被包含过了，则第二次包含就会失败，即使使用php://filter也一样。

>这个函数的作用是将指定文件包含到当前脚本中，并且只包含一次。如果文件已经在之前执行过程中被包含过，那么这个函数就不会再次包含它，以避免重复定义类、函数等。

那么此时如何解决呢？

方法就是使用“多重软连接”

PHP会将用户输入的文件名进行resolve，转换成标准的绝对路径，这个转换的过程会将../、./、软连接等都进行计算，得到一个最终的路径，再包含。每次包含都会经历这个过程，所以，只要是相同的文件，不管中间使用了../进行跳转，还是使用软连接进行跳转，**都逃不过最终被转换成原始路径的过程**，也就绕不过require_once。

但是，如果软连接跳转的次数超过了某一个上限，Linux的lstat函数就会出错，导致PHP计算出的绝对路径就会包含一部分软连接的路径，**也就和原始路径不相同的，即可绕过require_once限制。**

在linux下，最常见的软连接就是/proc/self/root，这个路径指向根目录。所以，我们可以多次使用这个路径：

```php
<?php require_once '/www/config.php'; include_once '/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/proc/self/root/www/config.php';
```

>/proc/self/root 是linux系统中的一个特殊软链接，他通常指向当前进程的根目录。这个软连接主要用于获取当前进程的根目录路径。
>
>`/proc` ：虚拟文件系统，提供对进程和内核信息的访问
>
>/proc/self：指向当前进程相关信息的符号链接。它是一个伪文件夹，它总是指向当前正常运行的进程目录。使用‘/proc/self’可以避免直接使用进程ID。
>
>`/proc/self/root`: 在当前进程的 `/proc/self` 目录下，`root` 是一个指向当前进程的根目录的软链接。