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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
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

contract ReceiveHelper{

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Caller is not owner");
        _;
    }

    function init(address _usdt) external onlyOwner{
        IERC20(_usdt).approve(owner, type(uint256).max);
    }
}

contract GP is ERC20{

    address public admin;
    address public uniswapV2Pair;
    address public uniswapV2Router; 
    address public project;
    address public dead;
    address public receiveHelper;
    address public usdt;
    uint256 public toProjectRate = 5;
    uint256 public toReceiverHelperRate = 10;
    uint256 public luidityAmount;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(ReceiveHelper).creationCode));

    
    constructor(address _uniswapV2Router,address _project)ERC20("GP","GP"){
        _mint(msg.sender,1000000e18);
        admin = msg.sender;
        dead = 0x000000000000000000000000000000000000dEaD;
        project = _project;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router(uniswapV2Router).factory()).createPair(
            usdt,
            address(this)
        );
        deploy();
    }

    modifier onlyOwner() {
        require(admin == msg.sender,"Caller is not owner");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 tokenAmount = amount;

        // Check if the sender is the contract address
        bool isContractSender = (sender == address(this));

        if (!isContractSender) {
            bool isSale = (recipient == uniswapV2Pair);

            if (isSale) {
                uint256 toProject = (amount * toProjectRate) / 100;
                uint256 toReflow = (amount * toReceiverHelperRate) / 100;
                tokenAmount = amount - toProject - toReflow;
                super._transfer(sender, project, toProject);
                super._transfer(sender, address(this), toReflow);
                luidityAmount += toReflow;
            } else {
                uint256 toBurn = (amount * 1) / 100;
                tokenAmount = amount - toBurn;
                super._transfer(sender, dead, toBurn);
            }
        }

        super._transfer(sender, recipient, tokenAmount);
        if(!nonSwap(sender, recipient)){
            _swapAndAdd();
        }
    }


    function _swapAndAdd() internal {
        uint256 halfAmount;
        if(luidityAmount > 0){
            halfAmount = luidityAmount / 2;
            _swap(halfAmount);
            uint256 usdtAmount = IERC20(usdt).balanceOf(receiveHelper);
            if(usdtAmount > 0){
                require(IERC20(usdt).transferFrom(receiveHelper, address(this), usdtAmount)); 
                _addLuidity(halfAmount, usdtAmount);
                luidityAmount = 0;
            }
        }
    }


    function nonSwap(address sender,address recipient) internal view returns(bool){
        bool isSale = (recipient == uniswapV2Pair);
        bool isPurs = (sender == uniswapV2Pair);
        bool isRouter = (sender == uniswapV2Router) || (recipient == uniswapV2Router);
        return isSale || isPurs || isRouter;
    }

    function _swap(uint256 amount) internal{
        _approve(address(this),uniswapV2Router, amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            receiveHelper, 
            block.timestamp + 10
        );
    }

    function _addLuidity(uint256 tokenAmount,uint256 usdtAmount) internal{

        _approve(address(this),uniswapV2Router, tokenAmount);
        IERC20(usdt).approve(uniswapV2Router, usdtAmount);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            address(this), 
            usdt, 
            tokenAmount, 
            usdtAmount,
            0, 
            0, 
            project, 
            block.timestamp
        );
    }

    function deploy() internal{
        address _helper;
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        bytes memory bytecode = type(ReceiveHelper).creationCode;
        assembly {
            _helper := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        receiveHelper = _helper;
        ReceiveHelper(receiveHelper).init(usdt);
    }

    function setRate(uint256 _project,uint256 _receiver)external   onlyOwner{
        toProjectRate = _project;
        toReceiverHelperRate = _receiver;
    }

    function setAdmin(address _admin) external onlyOwner{
        admin = _admin;
    }

    function setProjectAddress(address _project) external onlyOwner{
        project = _project;
    }


}
//router:0x10ED43C718714eb63d5aA57B78B54704E256024E
//project:0x76c3D05604BD33497a0A8dd961aEc0904652B9A7
//GP:0xAC7d010FaAd8Dd1E659229A2776ef354aC678256
