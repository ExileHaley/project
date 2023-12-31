// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IUniswapV2Router{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract Deep is ERC20{
    address public owner;
    address public uniswapV2Pair;
    address public slippage;
    uint256 public openTime;
    mapping(address => bool) public whitelist;

//["0xb54f31Ebf2e9181a2CBe6569a66f3DD8Db37F1ec","0x88e8A872DEC82e4797fcE4D34Fd292c3dC34F6D3","0x0098D5a3f97E2B036C5B92D55cBFc2EEc83e5647","0x26c1e99284434ecC14ca2F0c7Bf442622fc957b8","0x6fDcE78a8d71634C7E1547df78C3bCE4FA56dfFb","0x92ecfbDCBe5a417Ff663c49927830eb2Bd46959c","0x000000000000000000000000000000000000dEaD"]
    //router:0x10ED43C718714eb63d5aA57B78B54704E256024E
    //usdt:0x55d398326f99059fF775485246999027B3197955
    //slippage:0x4fe0Da085b5DDB4F85a540e5fCE3D73D8Aecd95E
    constructor(
        address[] memory addrs,
        address _router,
        address _usdt,
        address _slippage
    ) ERC20("Deep", "DEEP"){
        uint256 amount = 1000000000000e18;
        _mint(addrs[0], amount * 30 / 100);
        whitelist[addrs[0]] = true;
        _mint(addrs[1], amount * 5 / 100);
        whitelist[addrs[1]] = true;
        _mint(addrs[2], amount * 5 / 100);
        whitelist[addrs[2]] = true;
        _mint(addrs[3], amount * 5 / 100);
        whitelist[addrs[3]] = true;
        _mint(addrs[4], amount * 4 / 100);
        whitelist[addrs[4]] = true;
        _mint(addrs[5], amount * 1 / 100);
        whitelist[addrs[5]] = true;
        _mint(addrs[6], amount * 50 / 100);
        whitelist[addrs[6]] = true;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router(_router).factory()).createPair(_usdt,address(this));
        openTime = block.timestamp + 86400;
        slippage = _slippage;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Caller is not owner");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        bool isSellOrPurchase = recipient == uniswapV2Pair || sender == uniswapV2Pair;
        uint256 feeAmount = amount * 3 / 100;
        if (isSellOrPurchase) {
            if(sender == uniswapV2Pair && !whitelist[recipient])  require(block.timestamp >= openTime,"ERC20:Not started yet");
            super._transfer(sender, slippage, feeAmount);
            amount -= feeAmount;
        }
        super._transfer(sender, recipient, amount);
    }

    function setSlippage(address _slippage) public onlyOwner {
        slippage = _slippage;
    }

    function setWhitelist(address to, bool isWhite) external onlyOwner{
        whitelist[to] = isWhite;
    }

    function setOpenTime(uint256 time) external onlyOwner{
        openTime = time;
    }

    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

}

