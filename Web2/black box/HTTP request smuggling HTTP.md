### HTTP request smuggling HTTP

HTTP请求走私是一种用于干扰网站处理从一个或多个用户接收的HTTP请求序列的方式技术。请求走私漏洞通常很严重，允许攻击者绕过安全控制，未经授权访问敏感数据，并直接危害其他应用程序用户。

请求走私主要与HTTP/1请求相关联。但是，支持HTTP/2的网站可能容易受到攻击，具体取决于其后端架构。

当今的Web应用程序经常在用户和最终应用程序逻辑之间使用HTTP服务器链。用户将请求发送到前端服务器（有时称为负载均衡或反向代理），此服务器将请求转发到一个或多个后端服务器。这种类型的体系结构在现代基于云的应用程序中越来越普遍，在某些情况下是不可避免的。

当前端服务器将HTTP请求转发到后端服务器时，它通常会通过同一后端网络连接发送多个请求，因为这样效率高，性能更高。该协议非常简单;HTTP请求一个接一个地发送，接收服务器必须确定一个请求的结束位置和下一个请求的开始位置：

![image-20231103112320085](https://raw.githubusercontent.com/m1crofan/image/main/image-20231103112320085.png)

在这种情况下，前端和后端系统必须就请求之间的边界达成一致，这一点至关重要。否则，攻击者可能会发送一个不明确的请求，前端和后端系统会以不同的方式解释该请求：

![image-20231103112358601](https://raw.githubusercontent.com/m1crofan/image/main/image-20231103112358601.png)

攻击者导致后端服务器将其前端请求的一部分1解释为下一个请求的开始。它有效地预置到下一个请求之前，因此可能会干扰应用程序处理该请求的方式。这是一种请求走私攻击，可能会造成很严重的后果。

### How do HTTP request smuggling vulnerabilities  arise

大多数HTTP请求走私漏洞的出现是因为HTTP/1规范提供了两种不同的方法来指定请求结束位置：`Content-Length` `Transfer-Encoding` 

`Content-Length`标头很简单：它指定消息正文的长度（以字节为单位）。例如：

```http
POST /search HTTP/1.1
Host: normal-website.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 11

q=smuggling
```

`Transfer-Encoding` 标头可用于指定消息正文使用分块编码。这意味着消息正文包含一个或多个数据块。每个区块由以字节为单位的区块大小（以十六进制）组成，后跟换行符，后跟区块内容。消息以大小为零的块终止。例如：

```http
POST /search HTTP/1.1
Host: normal-website.com
Content-Type: application/x-www-form-urlencoded
Transfer-Encoding: chunked

b
q=smuggling
0
```

>许多安全测试人员不知道分块编码可以在HTTP请求中使用，原因有两个：
>
>- Burp Suite 会自动解压缩分块编码，使消息更易于查看和编辑
>- 浏览器通常不会在请求中使用分块编码，通常只在服务器响应中看到。

由于HTTP/1规范提供了两种不同的方法来指定HTTP消息的长度，因此单个消息可以同时使用这两种方法，从而使它们相互冲突。该规范试图通过声明如果`Content-Length` 和`Transfer-Encoding` 标头都存在，则应忽略标头`Content-Length` 来防止此问题。当只有有一台服务器在运行时，这可能可以避免歧义，但当两个或多个服务器链接在一起时，就不能了。这种情况下，问题可能由于两个原因而出现：

- 某些服务端不支持请求中的请求头`Transfer-Encoding` 
- 如果请求头以某种方式进行了模糊处理，则某些支持标头`Transfer-Encoding` 的服务器可能会被诱导不处理它。

如果前端服务器和后端服务器在（可能经过混淆的）`Transfer-Encoding` 方面的行为不同，则它们可能会在连续请求之间的边界上存在分歧，从而导致请求走私漏洞。

>端到端使用HTTP/2的网站本质上不受请求走私攻击的影响。由于HTTP/2规范引入了一种**用于指定请求长度的单一可靠机制**，因此攻击者无法引入所需的歧义。
>
>但是，许多网站都有使用HTTP/2的前端服务器，**但将其部署在仅支持HTTP/1的后端基础设施前面**。这意味着前端必须有效地将其收到的请求转换为HTTP/1。此过程称为HTTP降级。

### How to perform an HTTP request smuggling attack

经典的请求走私攻击涉及将`Content-Length` 头和`Transfer-Encoding` 头放入单个HTTP/1请求中，并对其进行操作，以便前端和后端服务器以不同的方式处理请求。完成此操作的确切方式取决于两台服务器的行为：

- CL.TE：前端使用`Content-Length` 后端服务器使用`Transfer-Encoding` 
- TE.CL：前端使用`Transfer-Encoding` 后端使用`Content-Length` 
- TE.TE：前端和后端都使用`Transfer-Encoding` ，但可以通过以某种方式混淆`Transfer-Encoding` 来诱导其中一台服务器不处理它。

>这些技术只能使用HTTP/1请求。默认情况下，浏览器和其他客户端使用HTTP/2与在TLS握手期间显式通告支持的服务器进行通信。

### CL.TE vulnerabilities

前端使用`Content-Length` 后端服务器使用`Transfer-Encoding` 。我们可以执行一个简单的HTTP请求走私攻击。

```http
POST / HTTP/1.1
Host: vulnerable-website.com
Content-Length: 13
Transfer-Encoding: chunked

0

SMUGGLED
```

前端服务器处理标头 `Content-Length` ，并确定请求正文的长度为 13 个字节，直到 `SMUGGLED` 的末尾。此请求将转发到后端服务器。

后端服务器处理 `Transfer-Encoding` 标头，因此将消息正文视为使用分块编码。它处理第一个块，该块的长度为零，因此被视为终止请求。以下字节 将保持未处理状态，后端服务器会将 `SMUGGLED` 这些字节视为序列中下一个请求的开始。

### TE.CL vulnerabilities

在这里，前端服务器使用标头，后端服务器使用 `Transfer-Encoding` `Content-Length` 标头。我们可以执行一个简单的HTTP请求走私攻击，如下所示：

```http
POST / HTTP/1.1
Host: vulnerable-website.com
Content-Length: 3
Transfer-Encoding: chunked

8
SMUGGLED
0
```

>要使用 Burp Repeater 发送此请求，您首先需要转到 Repeater 菜单并确保未选中“Update Content-Length”选项。
>
>需要在最后的 0 后面加上尾部序列 \r\n\r\n。

前端服务器处理 `Transfer-Encoding` 标头，因此将报文正文视为使用分块编码。它处理第一个块，该块的长度为 8 个字节，直到后面 `SMUGGLED` 的行的开头。它处理第二个块，该块的长度为零，因此被视为终止请求。此请求将转发到后端服务器。

后端服务器处理 `Content-Length` 头并确定请求正文的长度为 3 个字节，直到后面 `8` 的行的开头。以下以 开头的字节未处理，后端服务器会将这些字节 `SMUGGLED` 视为序列中下一个请求的开始。

