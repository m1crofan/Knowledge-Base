### What's Web cache poisoning?

攻击者利用Web服务器和缓存的行为，向其他用户提供有害的HTTP响应。

从根本上说，Web缓存投毒涉及两个阶段。首先，攻击者必须弄清楚如何从后端服务器引出无意中包含某种危险有效负载的响应。一旦成功，他们需要确保他们的响应被缓存并随后提供给预期的受害者。

投毒的Web缓存可能是分发大量不同攻击手段，利用XSS、js注入、开放重定向漏洞。

### How does a Web cache work？

如果服务器必须单独向每个HTTP请求发送新的响应，这可能会使服务器过载，从而导致延迟问题和糟糕的用户体验，尤其是在繁忙时期。缓存主要是减少此类问题的一种手段。

缓存位于服务器和用户之间，它保存（缓存）对特定请求的响应，通常保存固定的时间。如果另一个用户随后发送了等效的请求，则缓存只是直接向用户提供缓存响应的副本，而无需后端进行任何交互。通过减少服务器必须处理的重复请求数，大大减少了服务器上的负载。

![image-20231106195215002](https://raw.githubusercontent.com/m1crofan/image/main/image-20231106195215002.png)

### Cache keys

当Web缓存收到请求时，它首先必须确定是否有缓存的响应可以直接提供服务，或者是否必须转发请求以供后端服务器处理。缓存通过比较请求组件的预定义子集（缓存键）来识别等效请求。通常，浙江包含请求行和`host`头。

如果传入请求的缓存键与前一个请求的键匹配。则缓存会认为它们是等效的。因此，它将提供为原始请求生成的缓存响应的副本。这适用于具有匹配缓存键的所有后续请求，直到缓存的响应过期。

### Constructing a web cache poisoning attack

一般来说，构建基本的Web缓存投毒攻击包含以下步骤：

- Identify and evaluate unkeyed inputs
- Elicit a harmful response from the back-end server
- Get the response cached

#### Identify and evaluate unkeyed inputs

任何Web缓存投毒攻击都依赖于对`unkeyed` 的操纵，Web缓存在决定是否向用户提供缓存响应时会忽略未加密的输入。此行为意味着可以使用它们来注入有效负载并引发“中毒”响应。如果缓存该响应，则将提供给其请求具有匹配cache key的所有用户。因此，构建Web缓存投毒攻击的第一步是识别服务器支持的`unkeyed inputs`。

#### Elicit a harmful response from the back-end server

一旦找到了unkeyed input，下一步就是测试网站如何处理它。了解这一点对于成功引发有害响应至关重要。如果输入反映在服务器的响应中，而没有经过适当的审查，或者用于动态生成其他数据，那么这是Web缓存投毒的潜在入口点。

#### Get the response cached

操纵输入引发有害响应就说明成功了一半，但除非可以缓存响应，否则它起不了多大的危害。

是否缓存响应取决于各种因素，例如文件扩展名、内容类型、路由、状态码和响应头。需要花一些时间简单处理不同页面上的请求并研究缓存的行为方式。

![image-20231106201808983](https://raw.githubusercontent.com/m1crofan/image/main/image-20231106201808983.png)

### Exploiting web cache poisoning vulnerabilities

如果网站以不安全的方式处理`unkeyed` 的输入并允许缓存后续的HTTP响应，则容易受到Web缓存投毒的影响。

#### Using web chache poisoning to deliver an XSS attack

最简单的Web缓存投毒漏洞原理是，当unkeyed 输入保存在响应中，没有进行适当的处理。

如下：

```http
GET /en?region=uk HTTP/1.1
Host: innocent-website.com
X-Forwarded-Host: innocent-website.co.uk

HTTP/1.1 200 OK
Cache-Control: public
<meta property="og:image" content="https://innocent-website.co.uk/cms/social.png" />
```

>X-Forwarded-Host 是一个 HTTP 头部信息，通常由代理服务器或负载均衡器添加到传入的 HTTP 请求中。它用于指示原始客户端请求中使用的主机名（Host header）。
>
>当客户端发送 HTTP 请求时，其中会包含 Host 头部信息，指定要访问的主机名。然而，当请求经过代理服务器或负载均衡器时，这些设备可能会修改请求，并可能会添加 X-Forwarded-Host 头部来指示原始请求中的主机名。

对于Web缓存投毒`X-Forwarded-Host` 通常是`unkeyed`。在此例中，缓存可能会因此包含简单的XSS payload的响应而中毒：

```http
GET /en?region=uk HTTP/1.1
Host: innocent-website.com
X-Forwarded-Host: a."><script>alert(1)</script>"

HTTP/1.1 200 OK
Cache-Control: public
<meta property="og:image" content="https://a."><script>alert(1)</script>"/cms/social.png" />
```

如果缓存了此响应，所有访问`/en?region=uk` 的用户都将获得此XSS payload。

#### Using Web cache poisoning to exploit unsafe handing of resource imports

某些网站使用`unkeyed` http请求头来动态生成用于导入的资源（如外部托管的javascript）的URL。在这种情况下，如果攻击者将相应的http请求头修改为它们控制的域，他们可能会操纵URL以指向它们自己的恶意javascript文件。

如果缓存了包含此恶意URL的响应，则攻击者的javascript文件将被导入并在其请求具有匹配`cache key`的任何用户浏览器会话中执行。

```http
GET / HTTP/1.1
Host: innocent-website.com
X-Forwarded-Host: evil-user.net
User-Agent: Mozilla/5.0 Firefox/57.0

HTTP/1.1 200 OK
<script src="https://evil-user.net/static/analytics.js"></script>
```

做法就是 unkeyed的输入 会体现在response上，然后我利用他进行 做法就是找到上述的输入。

### Using Web cache poisoning to exploit cookie-handing vulnerabilities

Cookie 通常用于在响应中动态生成内容。一个常见的示例可能是指示用户首选语言的 cookie，然后使用该语言加载页面的相应版本：

```http
GET /blog/post.php?mobile=1 HTTP/1.1
Host: innocent-website.com
User-Agent: Mozilla/5.0 Firefox/57.0
Cookie: language=pl;
Connection: close
```

在此示例中，请求博客文章的波兰语版本。请注意，有关要提供的语言版本的信息仅包含在 `Cookie` 标头中。假设`cache key`包含请求行和标头，但不包含 `Host` `Cookie` 标头。在这种情况下，如果缓存了对此请求的响应，则尝试访问此博客文章的所有后续用户也将收到波兰语版本，无论他们实际选择了哪种语言。

缓存对 Cookie 的这种错误处理也可能被网络缓存投毒技术所利用。但实际上，与基于HTTP 请求头的缓存中毒相比，相对少见。当存在基于 cookie 的缓存中毒漏洞时，由于合法用户无意中对缓存进行了中毒，这些漏洞往往会很快被发现并解决。

### Using multiple headers to exploit web cache poisoning vulnerabilities

如上所述，某些网站容易受到简单的 Web 缓存中毒攻击。但是，其他攻击需要更复杂的攻击，只有当攻击者能够构建操纵多个未密钥输入的请求时，才会变得容易受到攻击。

例如，假设一个网站需要使用 HTTPS 进行安全通信。为了强制执行这一点，如果收到使用其他协议的请求，网站会动态生成一个重定向到使用 HTTPS 的自身：

```http
GET /random HTTP/1.1
Host: innocent-site.com
X-Forwarded-Proto: http

HTTP/1.1 301 moved permanently
Location: https://innocent-site.com/random
```

就其本身而言，这种行为并不一定容易受到攻击。但是，通过将此与我们之前了解的有关动态生成的 URL 中的漏洞的信息相结合，攻击者可能会利用此行为生成可缓存的响应，将用户重定向到恶意 URL。
