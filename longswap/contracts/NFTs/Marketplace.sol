// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


abstract contract Storage{
    address public admin;
    address public implementation;
}

contract Proxy is Storage{
    receive() external payable {}
    constructor() {
        admin = msg.sender;
    }

    modifier onlyOwner(){
        require(admin == msg.sender,"Proxy:Caller is not owner");
        _;
    }

    function _updateAdmin(address _admin) public onlyOwner{
        admin = _admin;
    }

    function setImplementation(address newImplementation) public onlyOwner{  
        implementation = newImplementation;
    }

    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}


interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract StorageV1 is Storage, ERC721Holder{
     enum State{
        sold,
        sellIn,
        cancelled
    }

    struct Option{
        uint256 optionId;
        address holder;
        uint256 tokenId;
        address payment;
        uint256 price;
        State   state;
    }
    mapping(uint256 => Option) public optionInfo;
    mapping(address => uint256[]) userOptionIds;

    struct Record{
        uint256 optionId;
        address payment;
        uint256 income;
        uint256 time;
    }
    mapping(address => Record[]) userRecords;
    
    uint256[] optionIds;
    mapping(uint256 => uint256) public index;

    mapping(address => bool) public supported;
    address public nfts;
    address dead;
    uint256 public feeRate = 50;
    uint256 public initNum = 1;
}



contract Marketplace is StorageV1{
   

    event Create(uint256 optionId, address holder, address payment, uint256 tokenId, uint256 price);
    event Operate(uint256 optionId, address operator, uint256 tokenId);

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(admin == msg.sender,"Caller is not owner");
        _;
    }

    function initialize(address _nfts,address _long,address _lt) external onlyOwner(){
        nfts = _nfts;
        dead = 0x000000000000000000000000000000000000dEaD;
        initNum = 1;
        feeRate = 50;
        supported[_long] = true;
        supported[_lt] = true;
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner{
        feeRate = _feeRate;
    }

    function setNfts(address _nfts) external onlyOwner{
        nfts = _nfts;
    }

    function addSupported(address token, bool isSupport) external onlyOwner{
        supported[token] = isSupport;
    }


    function createOption(uint256 tokenId, address payment,uint256 price) external {
        require(price > 0, "Invalid price params.");
        require(supported[payment],"Invalid payment address.");
        // IERC721(nfts).safeTransferFrom(msg.sender, address(this), tokenId);
        Option memory option = Option(initNum, msg.sender, tokenId, payment, price, State.sellIn);
        optionInfo[initNum] = option;
        userOptionIds[msg.sender].push(initNum);
        optionIds.push(initNum);
        index[tokenId] = optionIds.length - 1;
        emit Create(initNum, msg.sender, payment, tokenId, price);
        initNum++;
    }

    function purchaseOption(uint256 optionId) external {
        Option storage option = optionInfo[optionId];
        require(option.state == State.sellIn, "Invalid option state.");
        require(option.holder != msg.sender, "Invalid buyer.");
        uint256 fee = option.price + feeRate / 1000;
        TransferHelper.safeTransferFrom(option.payment, msg.sender, dead, fee);
        TransferHelper.safeTransferFrom(option.payment, msg.sender, option.holder, option.price - fee);
        IERC721(nfts).safeTransferFrom(address(this), msg.sender, option.tokenId);
        option.state = State.sold;
        _removeOption(optionId);
        userRecords[option.holder].push(Record(optionId,option.payment,option.price,block.timestamp));
        emit Operate(optionId, msg.sender, option.tokenId);
    }

    function cancelOption(uint256 optionId) external {
        Option storage option = optionInfo[optionId];
        require(option.state == State.sellIn, "Invalid option state.");
        require(option.holder == msg.sender, "Invalid operator.");
        // IERC721(nfts).safeTransferFrom(address(this), msg.sender, option.tokenId);
        option.state = State.cancelled;
        _removeOption(optionId);
        emit Operate(optionId, msg.sender, option.tokenId);
    }

    function _removeOption(uint256 optionId) internal{
        index[optionIds[optionIds.length - 1]] = index[optionId];
        optionIds[index[optionId]] = optionIds[optionIds.length - 1];
        optionIds.pop();
        delete index[optionId];
    }

    function emergencyWithdraw(address to,uint256[] calldata tokenIds) external onlyOwner(){
        for(uint i=0; i<tokenIds.length; i++){
            IERC721(nfts).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    function getOptions() external view returns(Option[] memory){
        Option[] memory options = new Option[](optionIds.length);
        for(uint i=0; i<optionIds.length; i++){
            Option memory option = optionInfo[optionIds[i]];
            options[i] = Option(option.optionId,option.holder,option.tokenId,option.payment,option.price,option.state);
        }
        return options;
    }

    function getUserOptions(address user) external view returns(Option[] memory){
        Option[] memory options = new Option[](userOptionIds[user].length);
        for(uint i=0; i<userOptionIds[user].length; i++){
            Option memory option = optionInfo[userOptionIds[user][i]];
            options[i] = Option(option.optionId,option.holder,option.tokenId,option.payment,option.price,option.state);
        }
        return options;
    }

    function getUserIncomeRecords(address user) external view returns(Record[] memory){
        return userRecords[user];
    }


}

//market:0x52a884f4CD72d1dDEFC967E6a90fB57cD712f2D2
//proxy:0xa2917088CE71cCc8b8C78F1DF00d9bd3b9477B56


//NFT:0x1c78d66577894e84502A1a87E3B5Ccc30DB44C04




//LT:0xD633d265dCA799104A15642Dc15c86a5660d9d23
//Long:0xfC8774321Ee4586aF183bAca95A8793530056353
