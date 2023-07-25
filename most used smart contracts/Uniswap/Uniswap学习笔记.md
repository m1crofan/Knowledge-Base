### 了解

![image-20230724170408748](https://raw.githubusercontent.com/m1crofan/image/main/image-20230724170408748.png)

从用户的视角来看，Uniswap就两个功能

- 兑换：用一种币去兑换别的币

- 提供流动性：提供一组资金池的两种货币，获得流动性挖矿的奖励

  > 图片的最后一栏`Liquidity Provider Fee` 表示的是兑换货币时需要支付的流动性费用，该币费用归全体提供流动性的用户所有。

### 仓库目录

#### uniswapV2-core

![image-20230724174441868](https://raw.githubusercontent.com/m1crofan/image/main/image-20230724174441868.png)

- Pair：每两种货币之间，都有单独的pair合约与之对应
- Factory：工厂合约，当第一次添加一个交易对的时候需要使用工厂合约去生成新的交易对合约

##### 库合约

![image-20230724174807575](https://raw.githubusercontent.com/m1crofan/image/main/image-20230724174807575.png)

由于solidity不能计算小数也容易产生溢出，所有需要`SafeMath`、`Math`进行计算。当uniswap计算流动性的时候需要使用`UQ112x112` 进行计算——能够计算小数点左右两边都有112位二进制数字。

#### v2-periphery

![image-20230724175512776](https://raw.githubusercontent.com/m1crofan/image/main/image-20230724175512776.png)

- Migrator:用于将V1的资金池迁移到V2中
- Rounter01/02：由于以太坊对单个合约的代码量有限制，所以这里分为了两个合约。

##### ./contracts/examples

![image-20230724180007821](https://raw.githubusercontent.com/m1crofan/image/main/image-20230724180007821.png)

uniswap支持闪电贷

### 合约结构

![image-20230725092904827](https://raw.githubusercontent.com/m1crofan/image/main/image-20230725092904827.png)

### 创建流动性

![image-20230725092937425](https://raw.githubusercontent.com/m1crofan/image/main/image-20230725092937425.png)

### 交易

![image-20230725093034405](https://raw.githubusercontent.com/m1crofan/image/main/image-20230725093034405.png)

### uniswap运行逻辑

![](https://raw.githubusercontent.com/m1crofan/image/main/Uniswap.png)



### 学习资料

[崔棉大师uniswap系列课程](https://www.youtube.com/watch?v=38mVbslZpS4&list=PLV16oVzL15MRR_Fnxe7EFYc3MAykL-ccv)

[uniswap官网](https://uniswap.org/)

[uniswapV2.info](https://v2.info.uniswap.org/)

[uniswapV2-core](https://github.com/Uniswap/v2-core/tree/master/contracts)

[uniswapv2-periphery](https://github.com/Uniswap/v2-periphery)