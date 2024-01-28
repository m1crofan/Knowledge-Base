## server-side request forgery(ssrf)

### what is SSRF?

服务端请求伪造允许攻击者使**服务器端**应用程序**向非预期位置**发送请求。攻击者可能会导致服务器连接到组织基础结构中的仅限内部的服务。在其他情况下，它们可能能够强制服务器连接到任意外部系统。这可能会导致泄露敏感数据，例如授权凭证。

### what is the impact of  SSRF attacks

成功的SSRF攻击通常会导致未授权的操作或访问组织内的数据。这可能位于易受攻击的应用程序中，也可能位于应用程序可以与之通信的其他后端系统上。在某些情况下，SSRF漏洞可能允许攻击者执行任意命令执行。

### Common SSRF attacks

SSRF 攻击通常利用信任关系从易受攻击的应用程序升级攻击并执行未授权的操作。这些信任关系可能与服务器有关，也可能与同一组织内的其他后端系统有关。

### SSRF attack against the server

在针对服务器的SSRF攻击中，攻击者使应用程序通过其环回网络接口向托管应用程序的服务器发出HTTP请求。这通常涉及提供具有主机名的URL，例如127.0.0.1或localhost。

例如，假设有一个购物应用程序，它允许用户查看特定商店中某件商品是否有库存。若要提供库存信息，应用程序必须**查询各种后端REST API**。 它通过前端HTTP请求将URL传递到相关的后端API端点来实现此目的。当用户查看库存状态时，其浏览器会发出以下请求。

>注：这里与通常理解C/S架构的前后端不同。此处前端是指网站的用户界面和视图呈现；后端是指网站后台，即处理交互的数据流和交互数据库等。

```http
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118

stockApi=http://stock.weliketoshop.net:8080/product/stock/check%3FproductId%3D6%26storeId%3D1
```

这会导致服务器向指定的URL发出请求，检索库存状态，并将其返回给用户。

在此示例中，攻击者可以修改请求以指定服务器本地URL：

```http
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118

stockApi=http://localhost/admin
```

正常情况下用户访问`/admin`需要经过身份验证的用户访问。但是，如果对`/admin`URL的请求来自本地计算机，则会绕过正常的访问控制。

为什么应用程序以这种方式运行，并隐式信任来自本地计算机的请求？这可能是由于各种原因造成的：

- 访问控制检查可以在位于应用程序服务器前面的其他组件中实现。当重新连接到服务器时，将绕过检查。
- 出于灾害恢复目的，应用程序可能允许来自本地计算机的任何用户在不登录的情况下进行管理访问。这为管理员提供了一种在丢失凭证时恢复系统的方法，这假定只有完全受信任的用户才会直接来自服务器。
- 管理界面可能监听主应用程序的不同端口号，并且用户可能无法直接访问。

### SSRF attacks against other back-end systems

在某些情况下，应用程序服务器能够与用户无法直接访问的后端系统进行交互。这些系统通常具有不可路由的专用IP地址。后端系统通常受网络拓扑保护，因此它们通常具有较弱的安全态势。在许多情况下，内部后端系统包含敏感功能，任何能够与系统交互的人都无需身份验证即可访问这些功能。

在前面的示例中，假设后端URL`https://192.168.0.68/admin` 上有一个管理界面。攻击者可以提交以下请求来利用SSRF漏洞，并访问管理界面：

```http
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118

stockApi=http://192.168.0.68/admin
```

### Circumventing common SSRF defenses

通常可以看到包含SSRF行为的应用程序以及旨在防止恶意利用的防御措施。通常，这些防御措施是可以规避的。

#### SSRF with blacklist-based input filters

某些应用程序会阻止包含主机名（127.0.0.1和 localhost）或敏感URL的输入（如/admin）。这种情况下，通常可以使用以下技术绕过过滤器：

- 使用`127.0.0.1`的替代ip表示形式，例如`2130706433`、或`017700000001` 或`127.1`.
- 注册自己的域名，解析为127.0.0.1.
- 使用URL编码（或双编码）或大小写变体对被阻止的字符串进行模糊处理
- 提供控制的URL，该URL将重定向到目标URL。尝试对目标URL使用不同的重定向代码以及不同的协议。例如，在重定向期间从`http:` 转换到`https：` 可以绕过某些SSRF过滤器。

**[实验]([Lab: SSRF with blacklist-based input filter | Web Security Academy (portswigger.net)](https://portswigger.net/web-security/ssrf/lab-ssrf-with-blacklist-filter))**

目标:成功访问管理界面`http://localhost/admin`删除用户`carlos`

![image-20231101211554442](https://raw.githubusercontent.com/m1crofan/image/main/image-20231101211554442.png)

直接访问目标，发现被拦截；因为有SSRF过滤器。接下来尝试绕过。

- 尝试换协议绕过（失败）
- 尝试更改`localhost`字符串的大小写（失败）
- 尝试`127.0.0.1`的替代ip表示形式
- 尝试URL编码（失败）

答案：使用URL双编码+`127.0.0.1`的替换形式`127.1`.

### SSRF with whitelist-based input filters

某些应用程序仅允许匹配的输入，即允许值的白名单。过滤器可能会在输入的开头查找匹配项，或者包含在输入中。可以通过利用URL解析中的不一致来绕过此过滤器。

URL规范包含许多功能，当URL使用此方法实现临时解析和验证时，这些功能会被忽略：

>在URL中@用于标识用户名和密码
>
>#用于指定网页中特定的片段或锚点

- 可以使用字符`@`将凭据嵌入到主机名之前的URL中。

  ```url
  https://expected-host:fakepassword@evil-host
  ```

- 可以使用`#`字符来指示URL片段。

  ```
  https://evil-host#expected-host
  ```

- 您可以利用 DNS 命名层次结构，将所需输入的内容放入由您控制的全限定 DNS 名称中。例如

  ```python
  https://expected-host.evil-host
  ```

- 可以对字符进行 URL 编码以混淆 URL 解析代码。如果实现过滤器的代码处理 URL 编码字符的方式与执行后端 HTTP 请求的代码不同，则此功能特别有用。您也可以尝试双重编码字符;某些服务器以递归方式对收到的输入进行 URL 解码，这可能会导致进一步的差异。

- 上述的组合使用。

[实验]([Lab: SSRF with whitelist-based input filter | Web Security Academy --- 实验室：带有基于白名单的输入过滤器的 SSRF |网络安全学院 (portswigger.net)](https://portswigger.net/web-security/ssrf/lab-ssrf-with-whitelist-filter))

目标：同样是访问`http://localhost/admin` 删除用户`carlos` 。

![image-20231102150222756](https://raw.githubusercontent.com/m1crofan/image/main/image-20231102150222756.png)

使用@绕过过滤器成功；但是后端报错说明后端识别的网址也是`stock.weliketoshop.net`。这个时候可以尝试往上加`#`

![image-20231102150536636](https://raw.githubusercontent.com/m1crofan/image/main/image-20231102150536636.png)

![image-20231102150615040](https://raw.githubusercontent.com/m1crofan/image/main/image-20231102150615040.png)

对#进行URL双编码尝试成功

![image-20231102150727088](https://raw.githubusercontent.com/m1crofan/image/main/image-20231102150727088.png)

成功的原因可能是：过滤器对URL进行一次编码后放行；后端对URL进行二次编码。

答案

```url
http://localhost:80%2523@stock.weliketoshop.net/admin/delete?username=carlos
```



### Bypassing SSRF filters via open redirection

有时候可以通过利用开放重定向漏洞来绕过基于过滤器的防御。

在前面的示例中，假设用户提交的URL经过严格验证，以防止恶意利用SSRF行为。但是，允许其URL的应用程序包含开放重定向漏洞。如果用于发出后端HTTP请求的API支持重定向，则可以构造一个满足筛选器的URL，并导致将请求重定向到所需的后端目标。

例如，应用程序包含一个开放重定向漏洞，其中以下URL：

```url
/product/nextProduct?currentProductId=6&path=http://evil-user.net
```

返回重定向到

```html
http://evil-user.net
```

可以利用开放重定向漏洞绕过URL过滤器，并利用SSRF漏洞

```http
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118

stockApi=http://weliketoshop.net/product/nextProduct?currentProductId=6&path=http://192.168.0.68/admin
```

此SSRF漏洞之所以有效，是因为应用程序首先验证提供的`stockAPI`URL是否位于允许的域上，而该域确实如此。然后，应用程序请求提供的URL,这会触发打开的重定向。它遵循重定向，并向攻击者选择的内部URL发出请求。

### Blind SSRF  vulnerabilities

当可以诱导应用程序向提供的URL发出后端HTTP请求，但后端请求的响应未在应用程序的前端响应中返回时，就会出现盲SSRF漏洞。

由于盲SSRF具有单向性，因此其影响通常低于正常的SSRF漏洞。它们不能被轻易地利用来从后端系统检索敏感数据，尽管在某些情况下可以利用它们来实现完整的远程代码执行。

检查盲SSRF漏洞最靠谱方法是使用out-of-band（OAST）技术。这包括尝试触发对您控制的外部系统的HTTP请求，并监控与该系统的网络交互。

仅仅识别可触发out-of-band的HTTP请求的盲SSRF漏洞本身并不能提供可利用性的途径。由于无法查看来自后端请求的响应1，因此该行为不能用于浏览应用程序服务器可以访问的系统上的内容。但是，仍然可以利用它来探测服务器本身或其他后端系统上的其他漏洞。可以扫描内部ip地址空间，发送旨在检测已知漏洞的有效负载。如果这些有效负载还采用blind out-of-band技术，则可能会在未修补的内部服务器上发现严重漏洞。

### Tinking

**Q**：可能出现SSRF漏洞点的位置有哪些呢？

**A**：[数仓安全测试之SSRF漏洞 ](https://zhuanlan.zhihu.com/p/618144548)

>黑盒的方法是找到所有调用外部资源的场景，进行漏洞排查，主要排查点包括
>
>- 图片加载下载
>- 社交分享功能
>- 文章收藏功能
>- 网站采集
>- 未公开的api接口
>- 从远程服务器请求资源

[SRC中的SSRF漏洞挖掘笔记1.0 ](https://xz.aliyun.com/t/12227)

>漏洞产生的原因是服务端提供了能够从其他服务器应用获取数据的功能，比如从指定的URL地址获取网页内容，加载指定地址的图片、数据、下载等等。漏洞URL示例: http://xxx.com/api/readFiles?url=http://10.1.11/xxx

### 扩展阅读

[【Blackhat】SSRF的新纪元：在编程语言中利用URL解析器-安全客 - 安全资讯平台 (anquanke.com)](https://www.anquanke.com/post/id/86527)

[SSRF漏洞原理、挖掘技巧及实战案例全汇总-腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1516352)
