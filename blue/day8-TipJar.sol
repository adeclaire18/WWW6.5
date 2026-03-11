// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    
    // 汇率：1 ETH = X 单位（如 1 ETH = 1000 USD）
    mapping(string => uint256) private conversionRates;
    string[] private supportedCurrencies;
    mapping(string => bool) private isCurrencySupported;
    
    uint256 private totalTipsReceived;

    struct TipRecord {
        string currency;       // 计价币种
        uint256 tokenAmount;   // 声明的代币数量（如 100 USD）
        uint256 ethAmount;     // 实际支付的 ETH（wei）
        uint256 timestamp;
        address tipper;
    }
    
    TipRecord[] private tipRecords;
    mapping(address => uint256) private tipperTotalContributions;

    // ============ 事件 ============
    event TipReceived(
        address indexed tipper,
        string currency,
        uint256 tokenAmount,
        uint256 ethAmount
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        // 汇率：1 ETH = X 单位
        _addCurrency("ETH", 1);      // 1 ETH = 1 ETH
        _addCurrency("USD", 1000);   // 1 ETH = 1000 USD
        _addCurrency("CNY", 5000);   // 1 ETH = 5000 CNY
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ============ 内部函数 ============
    
    function _addCurrency(string memory _currency, uint256 _rate) internal {
        require(_rate > 0, "Rate must > 0");
        if (!isCurrencySupported[_currency]) {
            isCurrencySupported[_currency] = true;
            supportedCurrencies.push(_currency);
        }
        conversionRates[_currency] = _rate;
    }

    /**
     * 核心计算：X 单位 = ? ETH
     * 公式：eth = (tokenAmount * 1e18) / rate
     * 例：100 USD，rate=1000 → (100 * 1e18) / 1000 = 0.1 ETH
     */
    function convertToEth(string memory _currency, uint256 _tokenAmount) 
        public 
        view 
        returns (uint256 ethAmount) 
    {
        require(isCurrencySupported[_currency], "Currency not supported");
        uint256 rate = conversionRates[_currency];
        return (_tokenAmount * 1 ether) / rate;
    }

    function _recordTip(
        address _tipper,
        string memory _currency,
        uint256 _tokenAmount,
        uint256 _ethAmount
    ) private {
        require(_tipper != address(0), "Invalid address");
        require(_tipper != owner, "Cannot tip yourself");
        require(_ethAmount > 0, "Amount must > 0");

        tipRecords.push(TipRecord({
            currency: _currency,
            tokenAmount: _tokenAmount,
            ethAmount: _ethAmount,
            timestamp: block.timestamp,
            tipper: _tipper
        }));

        totalTipsReceived += _ethAmount;
        tipperTotalContributions[_tipper] += _ethAmount;
        
        emit TipReceived(_tipper, _currency, _tokenAmount, _ethAmount);
    }

    // ============ 外部函数 ============

    /// @notice 直接用 ETH 打赏（1 ETH = 1 ETH）
    function tipInEth() public payable {
        require(msg.value > 0, "Must send ETH");
        _recordTip(msg.sender, "ETH", msg.value, msg.value);
    }

    /**
     * @notice 用虚拟币种计价，但实际支付 ETH
     * @param _currency 币种代码（如 "USD"）
     * @param _tokenAmount 该币种的金额（如 100 表示 100 USD）
     * @dev 必须附带准确的 ETH，否则交易失败
     */
    function tipInCurrency(string memory _currency, uint256 _tokenAmount) 
        public 
        payable 
    {
        require(isCurrencySupported[_currency], "Currency not supported");
        require(_tokenAmount > 0, "Amount must > 0");
        
        // ✅ 关键：计算需要多少 ETH，并验证用户确实付了这么多
        uint256 ethRequired = convertToEth(_currency, _tokenAmount);
        require(msg.value == ethRequired, "ETH amount mismatch");
        
        _recordTip(msg.sender, _currency, _tokenAmount, msg.value);
    }

    /// @notice 添加新币种（仅所有者）
    function addCurrency(string memory _currency, uint256 _rateToEth) 
        external 
        onlyOwner 
    {
        _addCurrency(_currency, _rateToEth);
    }

    /// @notice 提取所有 ETH（仅所有者）
    function withdrawTips() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);
    }

    // ============ 查询函数 ============

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getSupportedCurrencies() external view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getTipperContributions(address _tipper) 
        external 
        view 
        returns (uint256) 
    {
        return tipperTotalContributions[_tipper];
    }

    function getTotalTipsReceived() external view onlyOwner returns (uint256) {
        return totalTipsReceived;
    }

    /// @notice 获取汇率：1 ETH = ? 单位
    function getRate(string memory _currency) external view returns (uint256) {
        require(isCurrencySupported[_currency], "Currency not supported");
        return conversionRates[_currency];
    }
}