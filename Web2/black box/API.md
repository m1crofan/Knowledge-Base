**发现并测试前端未完全使用的API**

API testing

API 使软件系统和应用程序能够通信和共享数据。API测试很重要，因为API中的漏洞可能会破坏网站机密性、完整性和可用性。

所有动态网站都有API组成，因此SQL注入等经典Web漏洞可以归类为API测试。在本主题中，**我们将教你如何测试网站前端未完全使用的API**，重点介绍RESTful和JSON API。

要开始API测试，首先需要尽可能多地了解有关API的信息，以发现其攻击面。

首先，您应该确定API端点。这些是API接收有关其服务器上特定资源的请求的位置。例如，请考虑以下`GET`请求：

```http
GET /api/books HTTP/1.1
HOST: example.com
```

此请求的API端点是`/api/books`。这会导致与API进行交互，从图书馆中检索书籍列表。例如，另一个应用程序接口端可能是`/api/books/mystery`，这将检索到一个神秘书籍列表。

确定节点后，需要确定如何与它们进行交互。这使您能够构造有效HTTP请求来测试API。例如

- API处理的输入数据，包括必填参数和可选参数。
- API接受的请求类型，包括支持的HTTP方法和格式
- 速率限制和身份验证机制

API文档中通常记录着API如何使用，文档可以说人类可读和机器可读的形式。人类可读的文档旨在让开发人员了解如何使用API。它可能包括详细说明、示例和使用场景。机器可读文档旨在由软件处理，以自动执行API集成和验证等任务。它以JSON或XML等结构化格式编写。

即使API文档未公开提供，仍然可以通过浏览使用API的应用程序来访问它。为此，可以通过爬取或字典爆破出API文档所在的目录例如：

- `/api`
- `/swagger/index.html`
- `/openai.json`

如果确定资源的目录点，检查上级目录。例如，如果资源点在`/api/swagger/v1/users/123`，则应调查以下路径：

- `/api/swagger/v1`
- `/api/swagger`
- `/api`

Lab：Finding and exploiting and unused API endpoint

模糊测试以查找隐藏的端点

确定一些初始API端点后，可以通过模糊测试的手段发现隐藏的端点。例如，假设已确定以下用于更新用户信息的API点：`PUT /api/user/update`要识别隐藏的点，可以使用Burp Intruder对具有相同结构的其他资源进行模糊测试。例如，可以使用其他常见函数列表`delete`和`add`

查找隐藏参数的好用工具

- Burp Intruder
- Param miner
- Content disconvery

测试大规模任务的漏洞

批量赋值（也称为自动绑定）可能会无意中创建隐藏参数。当软件框架自动将请求参数绑定到内部对象的字段时，就会出现这种情况。因此，批量赋值可能会导致应用程序支持开发人员从未打算处理的参数。

识别隐藏参数

由于批量分配从对象字段创建参数，因此您通常可以通过手动检查API返回的对象来识别这些隐藏参数。

例如，考虑一个PATCH `/api/users/request` ，它使用户能够更新其用户名和电子邮件，并包含以下JSON

```json
{
    "username": "wiener",
   	"email": "wiener@example.com",
}
```

 `GET /api/users/123` 请求返回以下JSON：

```json
{
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "isAdmin": "false"
}
```

这可能表示隐藏 `id` 和 `isAdmin` 参数与更新的用户名和电子邮件参数一起绑定到内部用户对象。

若要测试是否可以修改枚举`isAdmin` 的参数值，请将其添加到请求中`PATCH`:

```json
{
    "username": "wiener",
    "email": "wiener@example.com",
    "isAdmin": false,
}
```

此外，发送`isAdmin` 参数值无效的`PATCH`请求：

```json
{
    "username": "wiener",
    "email": "wiener@example.com",
    "isAdmin": "foo",
}
```

如果应用程序的行为不同，这可能表明无效值会影响查询逻辑，但有效值不会。这可能表示用户可以成功更新参数。

### 服务端参数污染

某些系统包含无法从Internet直接访问的内部API。当网站在服务器端请求中嵌入用户输入到内部API而没有进行充分编码时，就会发生服务器端参数污染。这意味着攻击者可能能够操纵或注入参数，例如：

- 覆盖现有参数
- 修改应用程序行为
- 访问未授权的数据

可以测试任意用户输入是否存在任何类型的参数污染。例如，查询参数、表单字段、标头和URL路径参数都可能容易受到攻击。



