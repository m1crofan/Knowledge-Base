### 抢跑

用户可以使用distributeTree()对当前的Tree提出争议，如果resolveDispute()中的争议有效，则治理者将退还争议资金。

```solidity
function disputeTree(string memory reason) external {
	if (block.timestamp >= endOfDisputePeriod) revert InvalidDispute();
	IERC20(disputeToken).safeTransferFrom(msg.sender, address(this), disputeAmount);
	disputer = msg.sender;
	emit Disputed(reason);
}

function resolveDispute(bool valid) external onlyGovernorOrGuardian {
	if (disputer == address(0)) revert NoDispute();
	if (valid) {
		IERC20(disputeToken).safeTransfer(disputer, disputeAmount);
		_revokeTree();
	} 
	else {
		IERC20(disputeToken).safeTransfer(msg.sender, disputeAmount);
		endOfDisputePeriod = _endOfDisputePeriod(uint48(block.timestamp));
	}
	disputer = address(0);
	emit DisputeResolved(valid);
}
```

尽管已经有一个活跃的争议者，disputeTree()可以被另一个争议者再次调用，并且resolveDispute()只退款给最后一个争议者。

在最坏的情况下，有效的争议者可能会因为恶意的抢跑损失争议资金。

- 一个合法的争议者使用distributionTree()创建争议
- 由于它是有效的，管理者调用resolveDispute(valid = true)来接受争议并退还资金。
- 恶意用户通过抢跑的方式运行disputeTree()。
- 然后在resolveDispute(true)期间，争议资金将发送给第二个争议者，而第一个争议者将失去资金，尽管他是有效的。





