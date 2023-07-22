# Masterchef

## 1.MasterChef的数据结构

MasterChef在SushiSwap中处于核心地位，用户可以通过它进行流动性挖矿。MasterChef中包含两个主要的数据结构：UserInfo和PoolInfo

### 1.1 userinfo

```solidity
struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
```

amount是用户质押的LPToken数量，rewardDebt代表用户已经获取的奖励数量。

1.2 PoolInfo

```solidity
struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }
```

lp Token是ERC20标准代币，SunshiSwap最初的LPToken是Uniswap的流动性，Uniswap质押后生成的流动性其实是UniswapPair的代币，SushiSwap将UniswapPair的地址设置到pool里，就可以将Uniswap的流动性进行抵押操作。后来SushiSwap完成了一次迁移，LPToken就从Uniswap的流动性代币变成了SushiSwap的流动性代币。

allocPoint是质押池的分配比例，lastRewardBlock是上一次分配奖励的区块数。

allocPoint是质押池的分配比例，lastRewardBlock是上一次分配奖励的区块数。

accSushiPerShare是质押一个LPToken的全局收益，用户依赖这个计算实际收益，原理很简单，用户在质押LPToken的时候，会把当前accSushiPerShare记下来作为起始点位，当借出质押的时候，可以通过最新的accSushiPerShare减去起始点位，就可以得到用户实际收益。

### 1.3其他数据结构

```solidity
    SushiToken public sushi;
    // Dev address.
    address public devaddr;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
```

sushi是一个ERC20代币，质押流动性获得就是这种贷币奖励。

devaddr是开发者地址，用于分配sushi奖励的手续费

bonusEndBlock，刚开始sushi是借Uniswap的流动性进行质押的，为了吸引用户，设置了一个奖励值乘数BONUS_MULTIPLIER和一个奖励截至区块bonusEndBlock，在bonusEndBlock前的奖励获得数量都会乘以10，这个区块后会执行迁移，迁移后就没有了加倍奖励，后续这个值也就用不到了。

sunshiPerBlock，每个区块挖出来的sushi的数量

migrator，迁移工具类，实现原理就是根据UniswapPair创建一个一模一样的SushiSwapPair，然后用户的UniswapPair流动性赎回交易对（比如USDT/DAI），然后将交易对在SushiSwapPair中添加，获得SushiSwapPair的流动性代币，最后将SushiSwapPair的流动性代币进行质押。

totalAllocPoint是总共分配的点数

startBlock是开始区块

## 2、构造函数

```solidity
constructor(
        SushiToken _sushi,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        sushi = _sushi;
        devaddr = _devaddr;
        sushiPerBlock = _sushiPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }
```

MasterChef初始化传入sushi代币的地址（值为[0x6b3595068778dd592e39a122f4f5a5cf09c90fe2](https://etherscan.io/address/0x6b3595068778dd592e39a122f4f5a5cf09c90fe2)）

开发者地址（值为[0xe94b5eec1fa96ceecbd33ef5baa8d00e4493f4f3](https://etherscan.io/address/0xe94b5eec1fa96ceecbd33ef5baa8d00e4493f4f3)）

每个块分配sushi的数量（值为100*1e18），奖励结束区块（值为10850000）以及开始区块（值为10750000）

## 3、添加质押池

```solidity
function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }
```

代码很简单，生成一个poolInfo然后加入数组中，然后更新totalAllocPoint，其中_allocPoint是指这个池质押挖矿的比例。比如totalAllocPoint是1000， _allocPoint是100，每个区块一共挖100个，那么每个区块这个池分配到的就是100*（100/10000）=1

## 4、修改质押池参数

```solidity
function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }
```

修改质押挖矿的分配比例

## 5、执行迁移

```solidity
function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }
 
 
function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
```

管理员会先设置迁移器，然后针对单个质押池进行迁移。迁移流程先对迁移器进行授权(safeApprove),后面执行由migrator控制，migrator会返回一个新的LPToken，然后重置质押池。下面看看sushi的migrator是怎么操作的：

```solidity
function migrate(IUniswapV2Pair orig) public returns (IUniswapV2Pair) {
        require(msg.sender == chef, "not from master chef");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");
        address token0 = orig.token0();
        address token1 = orig.token1();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        if (pair == IUniswapV2Pair(address(0))) {
            pair = IUniswapV2Pair(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        //用户的流动性还给Uniswap
        orig.transferFrom(msg.sender, address(orig), lp);
        //Uniswap把质押的代币交易对给到sushiswap的pair
        orig.burn(address(pair));
        //sushiswap给用户发放流动性
        pair.mint(msg.sender);
        desiredLiquidity = uint256(-1);
        return pair;
    }
```

sushiswap一开始借助的是uniswap的流动性，因此上面的lp Token传过来的其实是UniswapPair，然后通过UniswapPair拿到具体的交易对里的两个token，然后在sushi中创建SushiSwapPair（都是IUniswapV2Pair接口的实现类），然后将用户在Uniswap的流动性赎回（先转给Uniswap，然后调用burn，这里burn的对象是pair，这样Uniswap会把两个质押token还到SushiSwapPair的地址），最后调用SushiSwapPair的mint给用户增发SushiSwapPair的流动性，从而完成用户流动性的迁移。

## 6、更新质押池收益

```solidity
function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        sushi.mint(devaddr, sushiReward.div(10));
        sushi.mint(address(this), sushiReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }
```

首先会计算质押池lp Token的数量，如果为0，就只更新lastRewardBlock。否则会先计算一个乘数multiplier

```solidity
// Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }
```

这里的计算是为了兼容bonusEndBlock，如果是to小于bonusEndBlock，说明质押池完全处于奖励挖矿阶段，会乘以一个倍数BONUS_MULTIPLIER,如果from大于bonusEndBlock，说明质押池完全没有参与奖励挖矿，所以简单的to-from就可以了。最后一个else是处理质押池部分参与奖励挖矿，部分是结束后的常规挖矿。

multiplier的计算是从lastRewardBlock到当前区块的奖励区块数，获取multiplier后开始计算这一段时间的sushiReward

```solidity
uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
```

multiplier*sushiPerBlock是总的sushi奖励，pool.allocPoint/totalAllocPoint是当前质押池的分配比例。接下来给开发者地址分配10%的sushiReward作为手续费，然后总的sushiReward分配给当前质押池。

然后计算一下accSushiPerShare进行累加。

最后更新lastRewardBlock。

## 7、查看用户质押收益

```solidity
function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }
```

前面所有的逻辑都在更新当前质押池的最新收益，逻辑和updatePool类似，但不执行mint，仅仅是逻辑上计算。最后一行通过用户质押的amount乘以accSushiPerShare，得到理论上用户一共获得的sushi数量，然后减去用户实际已经获得的sushi数量rewardDebt，就是剩余还未获得的数量。

## 8、用户质押LPToken进行挖矿

```solidity
function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeSushiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
```

先更新了质押池收益，然后计算用户未获得的sushi收益（如果用户之前已经质押了），将这些收益转到用户账户，然后将用户的LPToken转移到质押池，最后更新用户质押的LPToken数量，将最新的amount*accSushiPerShare设置为rewardDebt，这一步操作其实就是设置了一个用户奖励的起始点位，而上面的pendingSushi的计算恰恰依赖这个起始点位。

## 9、解除质押

```solidity
function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }
```

先更新了质押池收益，然后计算用户未获得的sushi收益，将这些收益转到用户账户，然后更新rewardDebt，最后把LPToken还给用户。