// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

//recevier:0x7165892ae2A237e11c049b485DB4855f51959824
//router:0x10ED43C718714eb63d5aA57B78B54704E256024E
//marketing:0xb78fFa48C0BcE1a8ecc24bA6890c97411F0906C0
//reflow:0x5b9B0F128cF036dc04b007Aa72630ACF8DC6910b
//正式subject:0x77E34975aBF6432Ed2029Cf7ea571C6ad678cF4F

contract Subject is ERC20{
    receive() external payable {}

    address public uniswapV2Pair;
    address public uniswapV2Router;
    address public owner;
    address public marketking;
    address public reflow;
    address dead;

    constructor(address _receiver,address _uniswapV2Router,address _marketking,address _reflow)ERC20("Subject 3","Subt"){
        _mint(_receiver, 150000000e18);
        uniswapV2Router = _uniswapV2Router;
        marketking = _marketking;
        reflow = _reflow;
        owner = msg.sender;
        dead = 0x000000000000000000000000000000000000dEaD;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router(uniswapV2Router).factory()).createPair(
            IUniswapV2Router(uniswapV2Router).WETH(),
            address(this)
        );
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"ERC20:Caller is not owner!");
        _;
    }

    function setOwner(address _owner) external onlyOwner(){
        owner = _owner;
    }

    function setInfo(address _marketking,address _reflow) external onlyOwner(){
        marketking = _marketking;
        reflow = _reflow;
    }


    function _transfer(address from, address to, uint256 amount) internal override{
        uint256 amountToken = amount;
        bool isPair = from == uniswapV2Pair || to == uniswapV2Pair;
        bool isRouter = from == uniswapV2Router || to == uniswapV2Router;

        if (!isPair && !isRouter) {
            _run();
            payable(marketking).transfer(address(this).balance);
        }

        if(isPair && !isRouter && from != address(this)){
            super._transfer(from, address(this), amountToken * 4 / 100);
            super._transfer(from, dead, amountToken * 2 / 100);
            amountToken = amountToken - (amountToken * 6 / 100);
        }

        super._transfer(from, to, amountToken);
    }


    function _run() internal {
        if (IERC20(uniswapV2Pair).totalSupply() > 0 && balanceOf(address(this)) > 0){
            uint256 amountToken = balanceOf(address(this));
            _tokenToBNB(amountToken * 75 / 100, address(this));
            _addLuidity(balanceOf(address(this)), address(this).balance * 33 / 100);
        }
    }

    function _tokenToBNB(uint256 amountIn,address to) internal{
        _approve(address(this), uniswapV2Router, amountIn);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(uniswapV2Router).WETH();

        IUniswapV2Router(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn, 
            0, 
            path, 
            to, 
            block.timestamp
        );
    }

    function _addLuidity(uint256 amountToken, uint256 amountBNB) internal{
        _approve(address(this), uniswapV2Router, amountToken);
        IUniswapV2Router(uniswapV2Router).addLiquidityETH{value:amountBNB}(
            address(this), 
            amountToken, 
            0, 
            0, 
            reflow, 
            block.timestamp
        );
    }

}
