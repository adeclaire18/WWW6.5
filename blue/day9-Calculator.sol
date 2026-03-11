
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;
    
    constructor(address _address) {
        owner = msg.sender;
        scientificCalculatorAddress = _address;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    // 方式1: 高级调用 - power 
    function power(uint256 base, uint256 exponent) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "Calculator not set");
        
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        return scientificCalc.power(base, exponent);
    }
    
    // 方式2: 低级调用 - squareRoot 
    function squareRoot(uint256 number) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "Calculator not set");
        /*
         * ABI 代表**应用程序二进制接口** 。你可以把它看作是合同的"通信协议"——它定义了当一方合同调用另一方时数据必须如何结构化。
         * 在使用高级函数调用（如 `otherContract.someFunction()`）时，Solidity 会为你处理 ABI 编码。但使用低级调用时， 你必须手动处理 。
         * abi.encodeWithSignature 构建了 EVM 在调用特定函数时期望的确切二进制格式。
         * `"squareRoot(int256)"` 是完整的函数签名（名称+参数类型）。
         * `number` 是我们作为参数传递的值。
         * 结果是字节数组 (`bytes memory`)，其中包含在区块链上调用该函数所需的所有信息。
         * /
        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);

        // success 告诉我们调用是否成功，returnData 包含函数返回的内容
        (bool success, bytes memory returnData) = scientificCalculatorAddress.staticcall(data);
        require(success, "Call failed");

        // 将原始返回数据解码回可用值，本例中这个数据类型是 uint256  
        return abi.decode(returnData, (uint256));
    }
}
