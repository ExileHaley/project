
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

interface IUniswapV2Pair {
    function skim(address to) external;
    function sync() external;
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
    uint256 marketingRate = 1;
    uint256 fundationRate = 2;

    address uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public uniswapV2Pair;
    uint256 public lastBurnTime;

    bool    public stateSwitch = true;
    bool    public openTrading;

    receive() external payable {}

    constructor(address _receiver,address _marketing,address _fundation,uint256 _marketingRate,uint256 _fundationRate)ERC20("FAI","FAI"){
        _mint(_receiver, 100000000e18);
        marketing = _marketing;
        fundation = _fundation;
        marketingRate = _marketingRate;
        fundationRate = _fundationRate;
        admin = msg.sender;
        lastBurnTime = block.timestamp;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router(uniswapV2Router).factory()).createPair(
            IUniswapV2Router(uniswapV2Router).WETH(),
            address(this)
        );
        
    }

    modifier onlyAdmin() {
        require(admin == msg.sender,"ERC20:Caller is not owner!");
        _;
    }

    function setConfig(address _marketing,address _fundation) external onlyAdmin(){
        marketing = _marketing;
        fundation = _fundation;
    }

    function setAdmin(address _admin) external onlyAdmin(){
        admin = _admin;
    }

    function update() external onlyAdmin(){
        lastBurnTime = block.timestamp;
    }

    function updateState(bool _stateSwitch) external onlyAdmin(){
        stateSwitch = _stateSwitch;
    }

    function setTrading(bool _openTrading) external onlyAdmin(){
        openTrading = _openTrading;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override{
        bool trading = (from == uniswapV2Pair || to == uniswapV2Pair);
        if(trading && from != address(this)) {
            require(openTrading, "no permit.");
            _tradingTransfer(from, to, amount);
        }else {
            _standardTransfer(from, to, amount);
        }
        
        bool nonswap = (!trading && from != uniswapV2Router && to != uniswapV2Router);
        //burn base condtion = time middle && no exchange
        if(block.timestamp - lastBurnTime >= 86400 && nonswap) {
            //burn condtion = totalSupply &&  switch enecmy
            if (IERC20(uniswapV2Pair).totalSupply() > 0 && stateSwitch){
                _burn(uniswapV2Pair, balanceOf(uniswapV2Pair) * 3 / 100);
                IUniswapV2Pair(uniswapV2Pair).sync();
                IUniswapV2Pair(uniswapV2Pair).skim(marketing);
                lastBurnTime = block.timestamp;
            }
        }    
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
            //compute marketing rate
            uint256 partOfMarketingRate = marketingRate * 100 / (marketingRate + fundationRate);
            //compute send token amount
            uint256 partOfMarketingToken = distribution * partOfMarketingRate / 100;
            //send eth to marketking
            payable(marketing).transfer(partOfMarketingToken);
            //send eth to fundation
            payable(fundation).transfer(distribution - partOfMarketingToken);
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


//FAI online:0xdAAb82F433c68249E3ddA9701732e22e796f9019