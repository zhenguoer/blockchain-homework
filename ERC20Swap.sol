// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//把接口合约IERC20里的函数实现，实现ERC20合约

import "./IERC20.sol";

contract ERC20 is IERC20 {
    //账户余额，授权额度，代币总供给，代币信息(名称、代号、小数位数)
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    //初始化代币名称、代号
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    //转账函数，调用方扣除amount数量代币，接收方增加相应代币
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    //代币授权，被授权方spender可以支配授权方amount数量的代币
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //授权转账，被授权方(msg.sender)将授权方sender的amount代币转给接收方recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //铸造代币，铸造任意数量的代币，实际中会加权限
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    //销毁代币
    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

contract Swap {
    address public transactionPool; //交易池地址
    address public tokenContract; //token合约地址
    address public x; //代币1
    address public y; //代币2
    uint256 public amountx; //交易池中代币1的数量
    uint256 public amounty; //交易池中代币2的数量
    uint256 public k; //交易池中代币1和代币2乘积
    uint256 public mod; //交易池中代币1和代币2的比值
    mapping(address => address) public address_address;
    mapping(uint256 => address) public amount_address; //交易池中代币1数量对应的代币1类型
    mapping(address => uint256) public address_amount; //交易池中代币1类型对应的代币1数量

    //事件
    event Swap(address indexed swaper, uint256 xAmount, uint256 yAmount);
    event LiquidityAdded(
        address indexed provider,
        uint256 xAmount,
        uint256 yAmount
    );

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    //初始化
    function initialize(address _transactionPool, uint256 _amount)
        external
        payable
    {
        IERC20 token = IERC20(tokenContract);
        transactionPool = _transactionPool;
        amount_address[_amount] = msg.sender;
        address_amount[msg.sender] = _amount;
        token.transfer(transactionPool, _amount);
        //  token.transfer(y, 10);
        //  token.approve(x, 100);
        //  token.approve(y, 100);

        //  token.transferFrom(msg.sender, x, _amountx);
        //       token.transferFrom(x, transactionPool, _amountx);

        /*        token.transferFrom(y, transactionPool, _amounty);
        amountx=_amountx;
        amounty=_amounty;
        amount_address[amountx]=x;
        amount_address[amounty]=y;
        k=amountx*amounty;
        mod=amountx/amounty;

/*       amountx=_amountx;
        amounty=_amounty;
        k=amountx*amounty;
        mod=amountx/amounty;
        x.transfer(transactionPool, amountx);
        y.transfer(transactionPool, amounty);

*/
    }

    //存储两个token的地址和信息
    function init(address _x, address _y) external {
        x = _x;
        y = _y;
        address_address[x] = y;
        address_address[y] = x;
        amountx = address_amount[x];
        amounty = address_amount[y];
        k = address_amount[x] * address_amount[y];
        mod = address_amount[x] / address_amount[y];
    }

    //存入x代币金额换出对应的y代币
    function SwapXforY(uint256 cunrushu)
        external
        returns (address huanchu, uint256 huanchushu)
    {
        IERC20 token = IERC20(tokenContract);
        token.transfer(transactionPool, cunrushu);
        amountx += cunrushu;
        huanchushu = amounty - k / amountx;
        amounty = k / amountx;
        address_amount[x] = amountx;
        address_amount[y] = amounty;
        //        mod = address_amount[x]/address_amount[y];
        token.transferFrom(transactionPool, y, huanchushu);
        emit Swap(x, cunrushu, huanchushu);
        return (y, huanchushu);
    }

    //存入y代币金额换出对应的x代币
    function SwapYforX(uint256 cunrushu)
        external
        returns (address huanchu, uint256 huanchushu)
    {
        IERC20 token = IERC20(tokenContract);
        token.transfer(transactionPool, cunrushu);
        amounty += cunrushu;
        huanchushu = amountx - k / amounty;
        amounty = k / amounty;
        address_amount[x] = amountx;
        address_amount[y] = amounty;
        //        mod = address_amount[x]/address_amount[y];
        token.transferFrom(transactionPool, x, huanchushu);
        emit Swap(y, cunrushu, huanchushu);
        return (x, huanchushu);
    }

    //增加流动性
    function addliquidity(uint256 cunru_x, uint256 cunru_y) external {
        require(
            cunru_x / cunru_y == address_amount[x] / address_amount[y],
            "The amount deposited does not meet the corresponding proportional relationship!"
        );
        IERC20 token = IERC20(tokenContract);
        token.transferFrom(x, transactionPool, cunru_x);
        token.transferFrom(y, transactionPool, cunru_y);
        amountx += cunru_x;
        amounty += cunru_y;
        address_amount[x] = amountx;
        address_amount[y] = amounty;
        emit LiquidityAdded(msg.sender, cunru_x, cunru_y);
    }
}
