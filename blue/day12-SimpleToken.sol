// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    // 可分割程度 decimals 为 小数点后有多少位
    uint8 public decimals = 18;
    // 用于追踪当前存在的代币总数
    uint256 public totalSupply;
    // 每个地址持有多少代币
    mapping(address => uint256) public balanceOf;
    // 一个嵌套映射，用于追踪谁被允许代表谁花费代币、以及花费多少
    // 解决的是"代付"场景，例如：拍卖会。在钱被真的转走之前，应该先创建额度
    // 举例：allowance[Alice][拍卖行合约] = 200
    // 意思是：Alice 允许拍卖行合约最多替她花 200 SIM
    mapping(address => mapping(address => uint256)) public allowance;
    // 每当有转账发生，每当有批准发生
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        // 定义总发行量
        // 假设你的代币使用 18 位小数，并且你想创建 100 个代币，那么需要将其表示为：100 * 10^18
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        // 给创建者发送所有代币
        balanceOf[msg.sender] = totalSupply;
        // 发送转账事件
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // 检查发送者的余额是否够用
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        // 执行内部函数完成转账
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // 将 _spender 的授权金额设置为 _value
        allowance[msg.sender][_spender] = _value;
        // 触发授权事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 真实转移代币，同时扣减授权额度
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // 检查被转走者的余额是否足够
        require(balanceOf[_from] >= _value, "Not enough balance");
        // 检查转走者授权金额是否足够
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");
        // 先改变记录
        allowance[_from][msg.sender] -= _value;
        // 再执行转账
        _transfer(_from, _to, _value);
        return true;
    }

    // 内部函数
    function _transfer(address _from, address _to, uint256 _value) internal {
        // 检查目标地址
        require(_to != address(0), "Invalid address");
        // 记账
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        // 触发事件
        emit Transfer(_from, _to, _value);
    }
}

