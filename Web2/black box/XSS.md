### What is cross-site scripting

跨站脚本攻击是一种Web安全漏洞，它允许攻击者**破坏**用户与易受攻击的应用程序的**交互**。它允许攻击者规避同源策略，该策略旨在将不同的网站彼此隔离。跨站脚本漏洞通常允许攻击者伪装成受害用户，执行用户能够执行的任何操作，并访问用户的任何数据。如果受害用户在应用程序中具有特权访问权限，则攻击者可能能够完全控制应用程序的所有功能和数据。

### How does XSS work

跨站脚本的工作原理是操纵易受攻击的网站，使其向用户返回恶意javascript。当恶意代码在受害者的浏览器中执行时，攻击者可以破坏他们与应用程序的交互。

### XSS proof of concept

可以通过注入payload来确认大多数类型的xss。该payload会导致浏览器执行任意js。长期以来，使用alert() 函数做漏洞证明已经成了惯例。

chrome从版本92（2021-7-20开始），将阻止跨域iframe调用`alert()`。这种情况下可以使用`print()` 函数。

>[alert() is dead, long live print() ](https://portswigger.net/research/alert-is-dead-long-live-print)

### What are the types of xss attacks

- 反射型XSS——恶意脚本来自于当前的HTTP请求
- 存储型XSS——恶意脚本来自于网站的数据库
- 基于DOM型XSS——漏洞存在于客户端代码而不是服务器端代码

#### Reflected cross-site scripting

反射型 XSS 是最简单的跨站点脚本。当应用程序在 HTTP 请求中接收数据并以不安全的方式将该数据包含在即时响应中时，就会出现这种情况。

下面是反射型XSS漏洞的简单演示

```python
https://insecure-website.com/status?message=All+is+well.
<p>Status: All is well.</p>
```

该应用程序不会对数据执行任何其他处理，因此攻击者可以构建如下攻击：

```http
https://insecure-website.com/status?message=<script>/*+Bad+stuff+here...+*/</script>
<p>Status: <script>/* Bad stuff here... */</script></p>
```

如果用户访问攻击者构造的 URL，则攻击者的脚本将在用户与应用程序会话的上下文中在用户的浏览器中执行。此时，脚本可以执行任何操作，并检索用户有权访问的任何数据。

### Stored  xss

### What's stored cross-site scripting?

当应用程序从不受信任的源接收数据并以不安全的方式将数据包含在其以后的http响应中时，就会出现存储的跨站脚本

假设一个网站允许用户提交对博客文章的评论，这些评论会显示给其他用户。用户使用HTTP请求提交评论，如下所示：

```http
POST /post/comment HTTP/1.1
Host: vulnerable-website.com
Content-Length: 100

postId=3&comment=This+post+was+extremely+helpful.&name=Carlos+Montoya&email=carlos%40normal-user.net
```

提交此评论后，访问博客文章的任何用户都会在应用程序中收到以下内容

```html
<p>This post was extremely helpful.</p>
```

如果应用程序不对数据执行任何处理，攻击者可以提交恶意评论

```html
<script>/* Bad stuff here... */</script>
```

在攻击者的请求中，此注释将URL编码为：

```
comment=%3Cscript%3E%2F*%2BBad%2Bstuff%2Bhere...%2B*%2F%3C%2Fscript%3E
```

### DOM-based XSS

#### what is DOM-based cross-site scripting

当js从攻击者**可控的来源**获取并将其传递到支持动态代码执行的接收器(如eval()或innerHTML)时，通常会出现基于DOM的xss漏洞。这使攻击者能够执行恶意JS

若要提供基于DOM的xss攻击，需要将数据放入源中，以便将其传播到接收器并导致执行任意javascript。

DOM XSS 最常见的来源是URL，通常使用`windows.location`对象访问该URL。攻击者可以构造一个链接，将受害者发送到易受攻击的页面，并在查询字符串和URL的片段部分中包含payload。



