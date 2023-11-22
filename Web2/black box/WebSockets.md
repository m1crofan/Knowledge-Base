WebSocket广泛用于现代Web应用程序。它们通过HTTP启动，并通过双向异步通信提供长期连接。

WebSocket可以用于实现各种功能，包括执行用户操作和传输敏感信息。WebSocket在需要低延迟或服务启动消息的情况下特别有用。

websocket连接通常使用客户端JS创建，如下所示

```js
var ws = new WebSocket("wss://normal-website.com/chat");
```

为了建立连接，浏览器和服务器通过HTTP执行WebSocket握手。浏览器发出WebSocket握手请求，如下所示：