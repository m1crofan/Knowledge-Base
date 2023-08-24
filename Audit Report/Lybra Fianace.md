### Business Logic flow

```solidity
function executeFlashloan(FlashBorrower receiver, uint256 eusdAmount, bytes calldata data) public payable {
    uint256 shareAmount = EUSD.getSharesByMintedEUSD(eusdAmount);
    EUSD.transferShares(address(receiver), shareAmount);
    receiver.onFlashLoan(shareAmount, data);
    bool success = EUSD.transferFrom(address(receiver), address(this), EUSD.getMintedEUSDByShares(shareAmount));
    require(success, "TF");

    uint256 burnShare = getFee(shareAmount);
    EUSD.burnShares(address(receiver), burnShare);
    emit Flashloaned(receiver, eusdAmount, burnShare);
}
```

- 并没有设置类似于：`require(receiver==msg.sender)`的条件

- 第四行,如果`receiver`合约没有实现`onFlashLoan`函数，智能合约执行会中断。但是，如果receiver合约有fallback函数，就能正常执行下去。

- 第五行，这个转账本应该属于授权转账，需要授权；但是transferFrom函数中没有授权判断

  - ```solidity
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
         address spender = _msgSender();
         if (!configurator. mintVault(spender)) {
             _spendAllowance(from, spender, amount);
         }
         _transfer(from, to, amount);
         return true;
    }
    ```

- 漏洞的危害性在第九行，会销毁receiver合约的代币，如果恶意攻击者设置`eusdAmount`的数量特别大，即使是5%的销毁比例；也可以销毁账户中全部的EUSD。

### Access control

源码：

```solidity
modifier onlyRole(bytes32 role) {
    GovernanceTimelock.checkOnlyRole(role, msg.sender);
    _;
    }

modifier checkRole(bytes32 role) {
    GovernanceTimelock.checkRole(role, msg.sender);
    _;
    }
```

修饰器并没有条件判断；应该改为如下

```solidity
modifier onlyRole(bytes32 role) {
    require(GovernanceTimelock.checkOnlyRole(role, msg.sender),"onlyRole");
    _;
    }

modifier checkRole(bytes32 role) {
    require(GovernanceTimelock.checkOnlyRole(role, msg.sender),"onlyRole");
    _;
    }
```

### contract proxy

在 Solidity 中，构造函数内的代码或全局变量声明的一部分不是已部署合约的运行时字节码的一部分。此代码仅在部署合约实例时执行一次。因此，逻辑合约构造函数中的代码永远不会在代理状态的上下文中执行。这意味着逻辑合约的构造函数中所做的任何状态更改都不会反映在代理的状态中。

源码：

```solidity
constructor(address _dao, address _curvePool) {
	GovernanceTimelock = IGovernanceTimelock(_dao);
	curvePool = ICurvePool(_curvePool);
}
```

对于这段构造函数；传入的`GovernanceTimelock`地址、`curvePool`地址在代理合约那里都是零值。

### Business Logic flow

```solidity
function mint(address _recipient, uint256 _mintAmount) external onlyMintVault MintPaused returns (uint256 newTotalShares) {
	require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

	uint256 sharesAmount = getSharesByMintedEUSD(_mintAmount);
	if (sharesAmount == 0) {
	//EUSD totalSupply is 0: assume that shares correspond to EUSD 1-to-1
		sharesAmount = _mintAmount;
	}
```

```solidity
function getSharesByMintedEUSD(uint256 _EUSDAmount) public view returns (uint256) {
        uint256 totalMintedEUSD = _totalSupply;
        if (totalMintedEUSD == 0) {
            return 0;
        } else {
            return _EUSDAmount.mul(_totalShares).div(totalMintedEUSD);
        }
    }
```

正如您在注释中看到的，检查了sharesAmount后，`//EUSD totalSupply is 0: assume that shares correspond to EUSD 1-to-1`。该代码假设如果sharesAmount = 0，则totalSupply必须为0，并且铸造的份额应等于输入的eUSD。然而，情况并非总是如此。

如果totalShares *_EUSDAmount <totalMintedEUSD，变量sharesAmount 可能为0，**因为这是整数除法**。如果发生这种情况，用户将通过少量 EUSD 调用铸币来获利，并享受 1-1 的铸币比例（每个 eUSD 1 份）。发生这种情况的原因是EUSD支持burnShares功能，该功能会删除用户的份额但保留totalSupply值。

例如：

- 一开始Bob调用mint函数传入参数1e18 的eUSD,他们收到1e18个份额
- Bob调用burnShares函数销毁1e18-1个份额。经过这个操作之后，这个合约中有1个份额以及1e18个eUSD；意味着，这一个份额值1e18个eUSD
- 如果Alice调用mint函数也传入1e18的eUSD，此时Alice收到1个份额（因为，此时一个份额值1e18个eUSD）
- 但是，如果Alice再次调用mint函数传入1e17的eUSD，Alice将收到1e17的份额，即使此时1一个份额值1e18个eUSD。这是因为`1e17 * (totalShares = 2) / (totalMintedEUSD = 2e18) = 0` 。

修复建议

在 EUSD.mint 函数中再次检查是否 shareAmount 为 0 并且totalSupply 不为 0，然后退出该函数而不铸造任何东西。
