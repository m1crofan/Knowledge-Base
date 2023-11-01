#### 安装

[安装教程(windows)](https://blog.csdn.net/weixin_51306597/article/details/130399689)

由于foundry是使用rust的编写的因此需要有rust的环境，rust默认安装在C盘好几个G，所以有更改安装路径的需求

![image-20230722200354316](https://raw.githubusercontent.com/m1crofan/image/main/image-20230722200354316.png)

![image-20230722200314088](https://raw.githubusercontent.com/m1crofan/image/main/image-20230722200314088.png)

#### 部署

[部署教程](https://blog.csdn.net/WongSSH/article/details/125837346?spm=1001.2101.3001.6650.7&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-125837346-blog-130399689.235%5Ev38%5Epc_relevant_anti_vip&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-125837346-blog-130399689.235%5Ev38%5Epc_relevant_anti_vip&utm_relevant_index=8)

foundry相比于别的框架的优点在于，脚本也同样是使用solidity语言编写的。

##### 智能合约部署

- 可以使用`forge create`命令用于部署
- `solidity script`方式部署

这里采用第二种方式部署一个简单的ERC20代币合约：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error NoPayMintPrice();
error WithdrawTransfer();
error MaxSupply();

contract SDUFECoin is ERC20, Ownable {
    
    uint256 public constant MINT_PRICE = 0.00000001 ether;
    uint256 public constant MAX_SUPPLY  = 1_000_000;

    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20 (_name, _symbol, _decimals) {}

    function mintTo(address recipient) public payable {
        if (msg.value < MINT_PRICE) {
            revert NoPayMintPrice();
        } else {
            uint256 amount = msg.value / MINT_PRICE;
            uint256 nowAmount = totalSupply + amount;
            if (nowAmount <= MAX_SUPPLY) {
                _mint(recipient, amount);
            } else {
                revert MaxSupply();
            }
        }
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}

```

部署脚本,在`script/token.s.sol`中写入以下内容：

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/token.sol";

contract TokenScript is Script {
    function run() external {
        vm.startBroadcast();

        SDUFECoin token = new SDUFECoin("SDUFECoinTest", "SDCT", 8);

        vm.stopBroadcast();
    }
}

```

`vm.startBroadcast()` 代表广播开始，智能合约的每一笔交易都需要全网广播以保证每一个节点获得交易信息并进行存储，在一定时间内将其打包进入区块。智能合约的部署也类似，也需要广播合约的字节码，保证节点将其打包进入以太坊区块。

`SDUFECoin token = new SDUFECoin("SDUFECoinTest", "SDCT", 8);`此行代码说明构造了一个完整的代币，此行代币所对照的字节码将被广播，这意味着合约上链。

`vm.stopBroadcast();` 关闭广播。

##### 本地部署

使用以下两种工具：

- `anvil`，该工具主要用于搭建一个完全本地化的以太坊环境，并提供10个含有1000ETH的账户。
- `cast`,工具主要用于与区块链RPC进行交互，比如进行合约内函数调用、发起交易、查询链上数据等，可以认为是一个命令行式的`etherscan`

在终端运行anvil命令，将看到如下输出：

![image-20230720113632464](C:\Users\microfan\AppData\Roaming\Typora\typora-user-images\image-20230720113632464.png)

在项目根目录下创建`.env`文件，输入以下内容：

```solidity
LOCAL_ACCOUNT=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

`ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`替换成上述十个账户中任意一个私钥值。

在终端内输入以下命令进行合约部署：

```solidity
forge script script/token.s.sol:TokenScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
```

##### cast学习


