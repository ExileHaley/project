// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

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

contract Marketplace{
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
    mapping(address => Option[]) userOptions;

    struct Record{
        uint256 optionId;
        address payment;
        uint256 income;
        uint256 time;
    }
    mapping(address => Record[]) userRecords;
    
    Option[] options;
    mapping(uint256 => uint256) index;

    mapping(address => bool) public supported;
    address public nfts;
    address public owner;
    address dead;
    uint256 public feeRate = 50;
    uint256 public initNum = 1;

    event Create(uint256 optionId, address holder, address payment, uint256 tokenId, uint256 price);
    event Operate(uint256 optionId, address operator, uint256 tokenId);

    constructor(){
        owner = msg.sender;
        dead = 0x000000000000000000000000000000000000dEaD;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Caller is not owner");
        _;
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

    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    function createOption(uint256 tokenId, address payment,uint256 price) external {
        require(price > 0, "Invalid price params.");
        require(supported[payment],"Invalid payment address.");
        IERC721(nfts).safeTransferFrom(msg.sender, address(this), tokenId);
        Option memory option = Option(initNum, msg.sender, tokenId, payment, price, State.sellIn);
        optionInfo[initNum] = option;
        userOptions[msg.sender].push(option);
        options.push(option);
        index[tokenId] = options.length - 1;
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
        IERC721(nfts).safeTransferFrom(address(this), msg.sender, option.tokenId);
        option.state = State.cancelled;
        _removeOption(optionId);
        emit Operate(optionId, msg.sender, option.tokenId);
    }

    function _removeOption(uint256 optionId) internal{
        options[index[optionId]] = options[options.length - 1];
        options.pop();
        delete index[optionId];
    }

    function emergencyWithdraw(address to,uint256[] calldata tokenIds) external onlyOwner(){
        for(uint i=0; i<tokenIds.length; i++){
            IERC721(nfts).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }


    function getOptions() external view returns(Option[] memory){
        return options;
    }

    function getUserOptions(address user) external view returns(Option[] memory){
        return userOptions[user];
    }

    function getUserIncomeRecords(address user) external view returns(Record[] memory){
        return userRecords[user];
    }


}
