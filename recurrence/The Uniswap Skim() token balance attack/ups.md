## UPS

### 相关信息

#### [交易](https://explorer.phalcon.xyz/tx/eth/0x3228cfb5b1b5413181c8b3abb6fd4d241917b537770aa99f5ab6a10b76ad1d27?line=35&debugLine=35)

![image-20230811154112013](https://raw.githubusercontent.com/m1crofan/image/main/image-20230811154112013.png)

在调用链中发现，攻击者调用了很多次`uniswap.skim`

#### 资金流

![0x3228cfb5b1b5413181c8b3abb6fd4d241917b537770aa99f5ab6a10b76ad1d27](https://raw.githubusercontent.com/m1crofan/image/main/0x3228cfb5b1b5413181c8b3abb6fd4d241917b537770aa99f5ab6a10b76ad1d27.png)

通过观察资金流我们不难发现，攻击手段依然是先通过闪电贷的方式展开，先从DVM中借贷了50WEH；最后，从`uniswap`的资金池中获取了63个WETH。返还50个WETH给DVM，获利13个WETH。

### 调用链分析

- 攻击者把通过闪电贷借到的50个WETH使用`WETH.transfer`转到资金池中，然后通过Uniswap的WETH-UPS这个资金池兑换为等值（算法层面上）数量的UPS。

- 通过`UPS.transfer`将兑换到的UPS又转回给对应资金池的pair合约。

  - > 注意⚠：此时是通过`UPS.transfer`转账，pair合约的`reserve1`并没有得到更新；攻击者故意为之，为下面利用skim()展开攻击提供条件。

- 接下来连续多次调用了`uniswap.skim()`方法，方法的形参to攻击者指定为pair合约本身。

### 函数分析

#### skim()

```solidity
function skim(address to) external lock {
	address _token0 = token0; // gas savings
	address _token1 = token1; // gas savings
	_safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
    _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }
```

在调用链分析的第二点中，我们强调了此时pair合约的`reserve1`并没有得到更新，也就是说此时的`reserve1+ups.transfer==balanceOf`,那么攻击者执行skim函数，就会把上一步通过`UPS.transfer`转给pair合约UPS对应的数量，按照攻击者设定的to地址转过去。

#### UPS._transfer()

```solidity
...        
        if (txType == 1) {
            uint256 totalMint = getMintValue(sender, amount);
            // uint256 mintSize = amount.div(100);
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            _totalSupply = _totalSupply.add(totalMint);
            emit Transfer(sender, recipient, amount);
        }
...
```

最值得看的是这一部分，在修改对应账户的代币余额之后，代币的总供应量会按照`getMintValue()`函数所返回的值增加。

#### getMintValue()

```solidity
    function getMintValue(address sender, uint256 amount) internal view returns(uint256) {
        uint256 expansionR = (_poolCounters[sender].pairTokenBalance).mul(_poolCounters[sender].startTokenBalance).mul(100).div(_poolCounters[sender].startPairTokenBalance).div(_poolCounters[sender].tokenBalance);
        uint256 mintAmount;
        if (expansionR > (Constants.getBaseExpansionFactor()).add(10000).div(100)) {
            uint256 mintFactor = expansionR.mul(expansionR);
            mintAmount = amount.mul(mintFactor.sub(10000)).div(10000);
        } else {
            mintAmount = amount.mul(Constants.getBaseExpansionFactor()).div(10000);
        }
        return mintAmount;
    }
```

无论走哪个分支，minitAmount都会有数据返回，总供应量`_totalSupply`增加。

#### balanceOf()

```solidity
    function balanceOf(address account) public view override returns (uint256) {
        uint256 currentFactor = getFactor();
        return getLargeBalances(account).div(currentFactor);
    }
```

#### getFactor()

```solidity
    function getFactor() public view returns(uint256) {
        if (isPresaleDone()) {
            return _largeTotal.div(_totalSupply);
        } else {
            return _largeTotal.div(Constants.getLaunchSupply());
        }
    }
```

`_totalSupply`总供应量不断增加，`currentFactor`不断减少，因此，`balanceOf()`不断增加。

### 漏洞成因

经过上述分析，我们可知：攻击者通过不断的调用`skim()`函数，转账次数也不断增加；资金池持有的UPS数量也越来越多。可是，pair合约中的`reserve1`始终没变。

![image-20230811184803297](https://raw.githubusercontent.com/m1crofan/image/main/image-20230811184803297.png)

在swap函数中，用户是否有足够的UPS兑换WETH是通过reserve1与balanceOf之间的差值确定的。在swap函数视角中，用户通过skim()函数给资金池增加的UPS代币数量和用户直接转等额的UPS数量效果是一样的。因此，用户可以换取和UPS等价值（算法层面上）的WETH。

