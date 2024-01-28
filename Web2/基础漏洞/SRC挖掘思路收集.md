### 思想

- 拿到一个业务点心中有对应的尝试
- 多尝试、多fuzzle

### 越权

#### **1.空数据包越权**

- 发现很多空的POST请求数据包，尝试在空的数据包中拼接一些参数

![image-20231219191725196](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219191725196.png)

- 加Content-Type头

```solidity
Content-Type: application/json: chareset=utf-8
```

返回的参数能够成功随着useid发生变化，说明可以越权了

#### 2.删数据越权

- 请求数据包

  ```url
  templateId=80&configurl=https://xx.xx.com/main.json&name=123&cover=http://xx.xx.com/1.jpg
  ```

- 越权—》修改templateId——发送数据包——无果
- 还会继续尝试吗？
  - 删除其他参数的值
    - templateId=81&configurl=&name=123&cover=
  - 拼接参数
    - templateId=81&configurl=xxx&name=123&cover=xxx&userid=1

**支付漏洞**

在支付时使用余额支付。

- 生成订单时 有一个参数代表产品的金额；改成零

![image-20231219203844939](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219203844939.png)

- 返回包

![image-20231219203946520](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219203946520.png)

继续放包，然后这个数据包就是最终支付的数据包（这个平台的支付业务总共有两次，第一次是生成订单预付款，第二次是直接支付金钱。）

![image-20231219204228260](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219204228260.png)

把40改成0放包，返回请勿修改订单价格

![image-20231219204324314](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219204324314.png)

这时候把上面复制的预付款成功的返回数据替换掉该请求数据；提示支付成功了。

![image-20231219204713500](https://raw.githubusercontent.com/m1crofan/image/main/image-20231219204713500.png)

### 任意用户漏洞

- 任意用户注册
  - 可覆盖注册
  - 不可覆盖注册
- 任意用户登录
- 任意用户密码重置

#### 案例

案例1：四位验证码可爆破

![image-20240103134914793](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103134914793.png)

案例2：验证码回显

![image-20240103135003426](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135003426.png)

案例3 只验证验证码 没有做绑定验证

应该是session和验证码绑定，但是没有和手机号绑定。

![image-20240103135205987](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135205987.png)

案例4 修改返回包

![image-20240103135250778](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135250778.png)

案例5 双写

![image-20240103135329185](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135329185.png)

案例六：第三方登录

![image-20240103135406005](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135406005.png)

案例7 任意验证码

![image-20240103135526178](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103135526178.png)

案例8 cookie由于手机号构成，将手机号改成11个1即可。

![image-20240103141702680](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103141702680.png)

url跳转

![image-20240103144025943](https://raw.githubusercontent.com/m1crofan/image/main/image-20240103144025943.png)