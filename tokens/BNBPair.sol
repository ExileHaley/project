
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Template is ERC20{

    address marketing;
    address fundation;
    address admin;
    uint256 marketingRate;
    uint256 fundationRate;

    address dead = 0x000000000000000000000000000000000000dEaD;
    address uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address uniswapV2Pair;
    uint256 tradingOpensBlock;

    receive() external payable {}

    constructor(address _marketing,address _fundation,uint256 _marketingRate,uint256 _fundationRate)ERC20("",""){
        _mint(msg.sender, 10000e18);
        marketing = _marketing;
        fundation = _fundation;
        marketingRate = _marketingRate;
        fundationRate = _fundationRate;
        admin = msg.sender;

        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router(uniswapV2Router).factory()).createPair(
            IUniswapV2Router(uniswapV2Router).WETH(),
            address(this)
        );
    }

    function setConfig(address _marketing,address _fundation) external {
        require(admin == msg.sender,"ERC20:Caller is not owner!");
        marketing = _marketing;
        fundation = _fundation;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override{
        bool lessTradingBlock = (from == uniswapV2Pair && block.number < tradingOpensBlock);
        bool trading = (from == uniswapV2Pair || to == uniswapV2Pair);
        /** 买入杀区块操作
         *1.跟pair地址进行交互，买
         *2.添加流动池后的10个区块内
         *3.to地址当前token只到账1%
        */
        if(lessTradingBlock) _lessTradingBlock(from, to, amount);
         /** 正常交易操作 Interaction
         *1.跟pair地址进行交互，买卖
         *2.to地址到账total - total * rate
         *3.当前合约地址到账total * rate
        */
        else if(trading) _tradingTransfer(from, to, amount);
        /** 转账操作
         *1.没有与pair进行交互
         *2.当前合约存储的代币数量大于10e18
         *3.执行交换操作
        */
        else _standardTransfer(from, to, amount);
        /**
         *1.检测uniswapV2Pair的totalSupply
         *2.如果大于0就更新tradingOpensBlock = 当前区块 + 10
        */
        if(IERC20(uniswapV2Pair).totalSupply() > 0) tradingOpensBlock = block.number + 10;
    }

    function _lessTradingBlock(address from, address to, uint256 amount) internal{
        super._transfer(from, to, amount * 1 / 100);
        super._transfer(from, address(this), amount * 99 / 100);
    }

    function _tradingTransfer(address from, address to, uint256 amount) internal{
        uint256 partOfRate = amount * (marketingRate + fundationRate) / 100;
        super._transfer(from, to, amount - partOfRate);
        super._transfer(from, address(this), partOfRate);
    }

    function _standardTransfer(address from, address to, uint256 amount) internal{
        super._transfer(from, to, amount);
        if(IERC20(uniswapV2Pair).totalSupply() > 0 && balanceOf(address(this)) > 0){
            uint256 swapAmount = balanceOf(address(this));
            swapTokensForEth(swapAmount, address(this));

            uint256 distribution = address(this).balance;
            uint256 partOfMarketingRate = marketingRate * 100 / (marketingRate + fundationRate);
            uint256 partOfMarketingToken = distribution * partOfMarketingRate / 100;
            payable(marketing).transfer(partOfMarketingToken);
            payable(marketing).transfer(distribution - partOfMarketingToken);
        }
    }

    function swapTokensForEth(uint256 amount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(uniswapV2Router).WETH();
        _approve(address(this), address(uniswapV2Router), amount);

        // Perform the swap here
        IUniswapV2Router(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp + 10
        );
    }

}


contract Test{

    address admin;
    address token;
    address uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    receive() external payable{}

    constructor(address _token){
        admin = msg.sender;
        token = _token;
    }

    function excuteExchange(uint256 amount) external {
        require(admin == msg.sender, "Caller is not owner!");
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router(uniswapV2Router).WETH();
        path[1] = token;

        IUniswapV2Router(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value:amount}(
            0, 
            path, 
            address(this), 
            block.timestamp + 10
        );
    }

    function withdrawETH(address to) external {
        require(admin == msg.sender, "Caller is not owner!");
        payable(to).transfer(address(this).balance);
    }

}