条件竞争是一种常见的漏洞类型，与业务逻辑缺陷密不可分的。当网站在没有足够保护措施的情况下同时处理请求时，就会发生这种情况。这可能导致多个不同的线程同时与相同的数据交互，从而导致“冲突”，从而导致应用程序中出现意外行为。条件竞争使用精心计时的请求来造成故意冲突，并利用这种意外行为实现恶意目的。

可能发生碰撞的时间段称为“比赛窗口”。例如，这可能是与数据库的两次交互之间的几分之一秒。

与其他逻辑缺陷一样，争用条件的影响很大程度上取决于应用程序及其发生的特定功能。

最广为人知的争用条件类型使您能够超出应用程序业务逻辑施加某种限制。

例如，考虑一家在线商店，该商店允许您在结账时输入促销代码以获得订单的一次性折扣。若要应用此折扣，应用程序可以执行以下步骤：

- 检查是否尚未使用此代码
- 将折扣应用于订单总额
- 更新数据库中的记录，以表明已使用此代码

如果以后尝试重用此代码，则在进程开始时执行的初始检查应阻止执行此操作：

![image-20231205124415732](https://raw.githubusercontent.com/m1crofan/image/main/image-20231205124415732.png)

现在考虑，如果以前从未应用过此折扣代码的用户几乎同时尝试应用两次，会发生什么。

![image-20231205124531001](https://raw.githubusercontent.com/m1crofan/image/main/image-20231205124531001.png)

这种攻击有多种变体，包括：

- 多次兑换礼品卡
- 对产品进行多次评分
- 提取或转账超过账户余额的现金
- [重复使用单个CAPTCHA解决方案](https://portswigger.net/research/cracking-recaptcha-turbo-intruder-style)
- [绕过反暴力破解速率限制]([Lab: Bypassing rate limits via race conditions | Web Security Academy (portswigger.net)](https://portswigger.net/web-security/race-conditions/lab-race-conditions-bypassing-rate-limits))

上述这些攻击的根本原因是相似的，它们都利用了安全检查与受保护操作之间的时间间隔。例如，两个线程可能同时查询数据库并确认折扣码尚未应用于购物车。然后两个线程都尝试应用折扣，导致它应用了两次。

**Multi-endpoint race conditions**

在处理单个请求期间执行付款验证和订单确认时，可能会发生此漏洞的变体。订单状态的状态机可能如下。

![image-20231205174429282](https://raw.githubusercontent.com/m1crofan/image/main/image-20231205174429282.png)

在这种情况下，可以通过在验证付款和最终确认订单之间的竞争窗口期间将更多的商品添加到购物车

**Single-endpoint race connditions**

向单个endpoint发送具有不同值的并行请求有时会触发条件竞争。例如，将用户ID和重置令牌存储在用户会话的密码重置机制。

在这种情况下，从同一会话发送两个并行密码重置请求，但使用两个不同的用户名，可能会导致以下条件竞争：

![image-20231205182046788](C:/Users/microfan/AppData/Roaming/Typora/typora-user-images/image-20231205182046828.png)

请注意所有操作完成后的最终状态：

- `session['reset-user'] = victim`
- `session['reset-token'] = 1234`

会话现在包含受害者的用户ID，但有效的重置令牌将发送给攻击者。

**Session-based locking mechanisms**

某些框架视图通过某种形式的请求锁定来防止意外的数据损坏。例如，PHP原生会话处理程序模块一次只处理每个会话的一个请求。

发现这种行为非常重要。因为它可以掩盖可利用的漏洞。如果您注意到所有请求都在按顺序处理，尝试使用不同的会话令牌发送每个请求。

**Time-sensitive attacks**

有时，可能找不到条件竞争，但以精确计时传递请求仍然可以揭示其他漏洞的存在。

其中一个例子就是使用时间戳来代替加密安全随机字符串生成安全令牌。

考虑一种仅使用时间戳随机化的密码重置令牌。在这种情况下，可以为两个不同的用户触发两次密码重置，而这两个用户都使用同一个令牌。你所需要做的就是为请求计时，使它们生成相同的时间戳。**Time-sensitive attacks**

有时，可能找不到条件竞争，但以精确计时传递请求仍然可以揭示其他漏洞的存在。

其中一个例子就是使用时间戳来代替加密安全随机字符串生成安全令牌。

考虑一种仅使用时间戳随机化的密码重置令牌。在这种情况下，可以为两个不同的用户触发两次密码重置，而这两个用户都使用同一个令牌。你所需要做的就是为请求计时，使它们生成相同的时间戳。

[Lab: Limit overrun race conditions ](https://portswigger.net/web-security/race-conditions/lab-race-conditions-limit-overrun)

>使用burp23.9以上的版本，并行发包；使得能够叠加使用优惠劵。

[Lab: Single-endpoint race conditions ](https://portswigger.net/web-security/race-conditions/lab-race-conditions-single-endpoint)

>当并行发包，修改为两个email地址，可能会存在把本应该发给B的邮件发给了A。
>
>![image-20231205170037225](https://raw.githubusercontent.com/m1crofan/image/main/image-20231205170037225.png)

[Lab: Bypassing rate limits via race conditions](https://portswigger.net/web-security/race-conditions/lab-race-conditions-bypassing-rate-limits)

>此实验的登录机制使用速率限制来防御暴力攻击。但是，由于条件竞争，可以绕过。

[Lab: Multi-endpoint race conditions](https://portswigger.net/web-security/race-conditions/lab-race-conditions-multi-endpoint)

>在线商店中的经典逻辑缺陷，您将商品添加到购物车或购物车，付款，然后在强制浏览订单确认页面之前将更多商品添加到购物车。

[Lab: Exploiting time-sensitive vulnerabilities ](https://portswigger.net/web-security/race-conditions/lab-race-conditions-exploiting-time-sensitive-vulnerabilities)

>这个实验包含密码重置上的漏洞，虽然没有条件竞争；但是我们可以通过发送定时请求来利用该机制。
>
>同时，会话处理程序模块一次只处理每个会话的一个请求。