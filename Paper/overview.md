任务

GAT+专家知识+SEnet

原有的专家知识

- 是否存在call.value
- 转账后是否扣余额
- 转账之前是否检查用户余额

改进的专家知识

- 是否存在call.value
- 转账后是否有状态更新
  - 而不仅仅是用户余额
- 当call.value函数为internal函数时，检查其他函数是否调用了该函数

重入漏洞

合约A

```solidity
pragma solidity ^0.8.21;
contract ContractA{
	uint256 private _totalSupply;
	uint256 private _allstake;
	mapping (address=>uint256)public _balances;
	bool check = true;
	
	modifier noreentrancy(){
		require(check);
		check = false;
		_;
		check = true;
	}
	/**
	* 根据合约凭证币总量与质押量计算质押价值，10e8为精度处理。
	**/
	function get_pice() public view virtual returns (uint256){
		if(_totalsupply==0||_allstake==0) return 10e8;
		return _totalSupply*10e8/_allstake;
	}
	/**
	*	用户质押，增加质押量并提供凭证币
	**/
	function deposit() public payable noreentrancy(){
		uint256 mintamount = msg.value*get_pice()/10e8;
		_allstake += msg.value;
		_balance[msg.sender] += mintamount;
		_totalSupply += mintamount;
	}
	/**
	*	用户提取，减少质押量并销毁凭证币总量
	**/
	function withdraw(uint256 burnamount) public noreentrancy(){
		uint256 sendamount = burnamount*10e8/get_price();
		_allstake -= amount;
		payable(msg.sender).call{value:sendamount}(“”);
		_balances[msg.sender] -= burnamount;
		_totalSupply -= burnamount;
	}
}
```

合约B

```solidity
pragma solidity ^0.8.21;

interface ContractA {

  function get_price() external view returns (uint256);

}

contract ContractB {

  ContractA contract_a;

  mapping (address => uint256) private _balances;

  bool check=true;

  modifier noreentrancy(){

    require(check);

    check=false;

    _;

    check=true;

  }

  constructor(){

  }

  function setcontracta(address addr) public {

    contract_a = ContractA(addr);

  }

  /**

   * 质押代币，根据 ContractA 合约的 get_price() 来计算质押代币的价值，计算出凭证代币的数量

  **/

  function depositFunds() public payable noreentrancy(){

    uint256 mintamount=msg.value*contract_a.get_price()/10e8;

    _balances[msg.sender]+=mintamount;

  }

  /**

   * 提取代币，根据 ContractA 合约的 get_price() 来计算凭证代币的价值，计算出提取代币的数量

  **/

  function withdrawFunds(uint256 burnamount) public payable noreentrancy(){

    _balances[msg.sender]-=burnamount;

    uint256 amount=burnamount*10e8/contract_a.get_price();

    msg.sender.call{value:amount}("");

  }

  function balanceof(address acount)public view returns (uint256){

    return _balances[acount];

  }

}
```

