// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Store{
    address public admin;
    address public implementation;
}

contract Proxy is Store{
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
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



contract StoreV1 is Store{

    enum Target{
        INVITE,
        REMOVE
    }

    //token
    address public usdt;
    address public token;
    address public lp;

    //address first
    address public leader;

    //swap
    address public uniswapV2Router;

    //burn 
    address public dead;

    //user info
    struct User{
        address inviter;
        address additionalInviter;

        uint256 staking;
        uint256 property;

        mapping(uint256 => uint256) dailyGrades;
        mapping(uint256 => uint256) weeklyRemove;

        address[] subordinates;

    }
    mapping(address => User) public userInfo;

    //lucky
    address[] public fortunes;
    uint256 public lastFortunesTime;

    //Ranking
    //remove Ranking
    mapping(uint256 => address[]) public removeRankings;
    mapping(uint256 => mapping (address => bool)) removeDataAlreadyAdd;
    uint256 public removeCurrentTime;

    //invite Ranking
    mapping(uint256 => address[]) public inviteRankings;
    mapping(uint256 => mapping (address => bool)) inviteDataAlreadyAdd;
    uint256 public inviteCurrentTime;

    //data
    uint256 public totalMembers;
    uint256 public totalUsdts;

    //total surplus
    uint256 public surplus;

    //withdraw
    mapping(string => bool) public extractedMark;

    //manager
    address public operator;


    //get data
    struct Assemble{
        address member;
        uint256 amount;
    }
}


contract Membership is StoreV1{
    modifier onlyOperator() {
        require(msg.sender == operator,"Membership:Invalid operator address");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin,"Membership:Invalid admin address");
        _;
    }

    function setOperator(address _operator) external onlyOwner(){
        operator = _operator;
    }

    function initialize(address _token,address _lp,address _leader,address _operator) external onlyOwner(){
        token = _token;
        lp = _lp;
        leader = _leader;
        operator = _operator;
        inviteCurrentTime = block.timestamp;
        removeCurrentTime = block.timestamp;
        lastFortunesTime = block.timestamp;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        dead = 0x000000000000000000000000000000000000dEaD;
        totalMembers += 1;
    }


    function invite(address _inviter, address _member) external{
        if(_inviter != leader) require(userInfo[_inviter].inviter != address(0),"MemberShip: Invalid inviter address");
        require(userInfo[_member].inviter == address(0),"MemberShip: Invalid member address");
        userInfo[_member].additionalInviter = _inviter;
        totalMembers += 1;
        recursiveInvite(_inviter, _member);
    }

    function findSubordinateWithSpace(address userAddress) internal view returns (address) {
        for (uint i = 0; i < userInfo[userAddress].subordinates.length; i++) {
            if (userInfo[userInfo[userAddress].subordinates[i]].subordinates.length < 2) {
                return userInfo[userAddress].subordinates[i];
            }
        }
        return address(0);
    }

    function recursiveInvite(address _inviter, address _member) internal {
        if (userInfo[_inviter].subordinates.length >= 2) {
            address subToAddUnder = findSubordinateWithSpace(_inviter);
            if (subToAddUnder == address(0)) {
                for (uint i = 0; i < userInfo[_inviter].subordinates.length; i++) {
                    recursiveInvite(userInfo[_inviter].subordinates[i], _member);
                }
            } else {
                recursiveInvite(subToAddUnder, _member);
            }
        } else {
            userInfo[_member].inviter = _inviter;
            userInfo[_inviter].subordinates.push(_member);
        }
    }

    function _swapUSDTForToken(uint256 amount)internal{
        IERC20(usdt).approve(uniswapV2Router, amount);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = token;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            address(this), 
            block.timestamp + 10
        );
    }

    function _addLuidity(uint256 tokenAmount,uint256 usdtAmount) internal returns(uint amountUSDT,uint amountToken,uint luidity){

        IERC20(token).approve(uniswapV2Router, tokenAmount);
        IERC20(usdt).approve(uniswapV2Router, usdtAmount);

        (amountUSDT,amountToken,luidity) = IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            token, 
            usdtAmount, 
            tokenAmount,
            0, 
            0, 
            address(this), 
            block.timestamp
        );
    }

    function getAccessAmount(uint256 amount) public view returns(bool supp) {
        uint256 middleDiv = totalMembers / 1000;
        uint256 middleMod = totalMembers % 1000;

        if (middleMod > 0){
            if (middleDiv == 0)  supp = amount == 1e20;
            else  if(middleDiv < 3) supp = amount == middleDiv * 1e20;
            else supp = true;
        }
    }

    function _reward(address member, uint256 amountStake, uint256 amountLP) public {
        address inviter = userInfo[member].additionalInviter;
        User storage upper = userInfo[inviter];
        uint256 totalPart = amountLP * 40 / 100;

        if (upper.staking == 0) {
            surplus += totalPart;
        }else if(upper.staking >= amountStake || upper.staking >= 300e18){
            upper.property += totalPart;
        }else{
            uint256 surplusLP = amountLP / (upper.staking / amountStake) * 40 / 100;
            upper.property += surplusLP;
            surplus += totalPart - surplusLP ;
        }
    }

    function _loopReward(address member, uint256 amountLP) public returns (uint256) {
        address _loop = userInfo[member].inviter;
        uint256 iterations = 0;
        for (uint256 i = 0; i < 100 && _loop != address(0); i++) {
            if (userInfo[_loop].staking > 0) {
                userInfo[_loop].property += amountLP * 2 / 1000;
            } else {
                surplus += amountLP * 2 / 1000;
            }
            _loop = userInfo[_loop].inviter;
            iterations = i + 1;
        }
        return iterations;
    }


    function _distributeLuckyRankings(address[] memory rankings) internal {
        uint256 totalReward = surplus / 100;
        uint256 thirtyPercent = totalReward * 30 / 100;
        uint256 twentyPercent = totalReward * 20 / 100;
        uint256 startIndex = (rankings.length > 30) ? rankings.length - 30 : 0;
        for (uint256 i = startIndex; i < rankings.length; i++) {
            uint256 share;
            if (i >= rankings.length - 5) {
                share = thirtyPercent / 5;
            } else if (i >= rankings.length - 10) {
                share = twentyPercent / 5;
            } else if (i >= rankings.length - 20) {
                share = thirtyPercent / 10;
            } else {
                share = twentyPercent / 10;
            }
            userInfo[rankings[i]].property += share;
            surplus -= share;
        }
    }

    function updateInviteList(address member, uint256 amount) public{
        address _inviter = userInfo[member].additionalInviter;
        userInfo[_inviter].dailyGrades[inviteCurrentTime] += amount;
        if(!inviteDataAlreadyAdd[inviteCurrentTime][_inviter] && _inviter != address(0)){
            inviteRankings[inviteCurrentTime].push(_inviter);
            inviteDataAlreadyAdd[inviteCurrentTime][_inviter] = true;
        } 
    }

    function _distributeLuckyReward(address member) public{
        if(block.timestamp >= lastFortunesTime + 86400 && fortunes.length > 0){
            _distributeLuckyRankings(fortunes);
        }else{
            fortunes.push(member);
            lastFortunesTime = block.timestamp;
        }
    }

    function provide(address member, uint256 amount) external {
        User storage user = userInfo[member];
        if(member != leader) require(user.inviter != address(0),"Membership: Invalid inviter address");
        require(getAccessAmount(amount),"Membership: Invalid provide amount");

        TransferHelper.safeTransferFrom(usdt, member, address(this), amount);
        user.staking += amount;
        _swapUSDTForToken(amount / 2);

        uint256 amountUSDT = IERC20(usdt).balanceOf(address(this));
        uint256 amountToken = IERC20(token).balanceOf(address(this));
        (uint _amountToken, ,uint _luidity)=_addLuidity(amountToken, amountUSDT);

        TransferHelper.safeTransfer(token, dead, amountToken - _amountToken);


        user.property += _luidity * 40 / 100;

        totalUsdts += amount;

        _reward(member,amount,_luidity);
        uint256 index = _loopReward(member, _luidity);
        uint256 hierarchy = _luidity * 20 / 100;
        uint256 pre = _luidity * 2 / 1000;
        surplus = surplus + (hierarchy - pre * index);

        updateInviteList(member, amount);

        _distributeLuckyReward(member);
    }

    function withdraw(address member,uint256 amount) external{
        require(userInfo[member].property >= amount,"MemberShip: Invalid withdraw lp`s amount");
        userInfo[member].property -= amount;
        TransferHelper.safeTransfer(lp, member, amount);
    }

    function managerWithdraw(address target,address receiver, uint256 amount) external onlyOwner(){
        uint256 total = IERC20(target).balanceOf(address(this));
        require(total >= amount,"MemberShip: Invalid manager withdraw lp`s amount");
        TransferHelper.safeTransfer(target, receiver, amount);
    }


    function removeLuidity(address member, uint256 amount) external {
        User storage user = userInfo[member];
        require(user.property >= amount,"MemberShip: Invalid remove lp`s amount!");
        uint256 targetAmount = amount * 97 / 100;
        user.property -= amount;
        surplus += (amount - targetAmount);
        user.weeklyRemove[removeCurrentTime] += amount;
        if (!removeDataAlreadyAdd[removeCurrentTime][member]) {
            removeRankings[removeCurrentTime].push(member);
            removeDataAlreadyAdd[removeCurrentTime][member] = true;
        }
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = token;
        IERC20(lp).approve(uniswapV2Router, targetAmount);
        IUniswapV2Router(uniswapV2Router).removeLiquidity(
            token, 
            usdt, 
            targetAmount, 
            0, 
            0, 
            member, 
            block.timestamp + 10
        );
    }

    function getMemberGrades(Target target,address member) external view returns(uint256){
        if (target == Target.INVITE) return userInfo[member].dailyGrades[inviteCurrentTime];
        else return userInfo[member].weeklyRemove[removeCurrentTime];
    }

    function multiGetMemberGrades(Target target,address[] memory member) external view returns(Assemble[] memory){
        Assemble[] memory grades = new Assemble[](member.length);
        if (target == Target.INVITE){
            for(uint i=0; i<grades.length; i++){
                grades[i] = Assemble(member[i],userInfo[member[i]].dailyGrades[inviteCurrentTime]);
            }
        }

        if (target == Target.REMOVE){
            for(uint i=0; i<grades.length; i++){
                grades[i] = Assemble(member[i],userInfo[member[i]].weeklyRemove[removeCurrentTime]);
            }
        }
        return grades;
    }


    function getRankings(Target target) external view returns(address[] memory){
        if (Target.INVITE == target) return inviteRankings[inviteCurrentTime];
        else return removeRankings[removeCurrentTime];
    }

    function getLuckyRankings() external view returns(address[] memory lucky, uint256 lastTime) {
        uint256 arrayLength = fortunes.length;
        uint256 startIndex;
        if (arrayLength <= 30) {
            startIndex = 0;
        } else {
            startIndex = arrayLength - 30;
        }

        lucky = new address[](arrayLength - startIndex);
        for (uint256 i = 0; i < lucky.length; i++) {
            lucky[i] = fortunes[startIndex + i];
        }
        lastTime = lastFortunesTime;
    }


    event Rate(uint256 percent);

    function distributeRankings(address[] memory members,Target target,string memory mark) external onlyOperator(){

        uint256 percent = (target == Target.REMOVE) ? 2 : 7;
        emit Rate(percent);
        if(target == Target.REMOVE) removeCurrentTime = block.timestamp;
        else inviteCurrentTime = block.timestamp;
        uint256 totalReward = surplus * percent / 100;
        uint256 thirtyPercent = totalReward * 30 / 100;
        uint256 twentyPercent = totalReward * 20 / 100;

        for(uint i=0; i<members.length; i++){
            uint256 share;
            if (i < 5) {
                share = thirtyPercent / 5;
            } else if (i < 10) {
                share = twentyPercent / 5;
            } else if (i < 20) {
                share = thirtyPercent / 10;
            } else {
                share = twentyPercent / 10;
            }
            userInfo[members[i]].property += share;
            surplus -= share;
        }
        extractedMark[mark] = true;
    }


    function getUserInfo(address member) external view returns(
        address _inviter,
        address _additionalInviter,
        uint256 _staking, 
        uint256 _property,
        uint256 _dailyGrades,
        uint256 _weeklyRemove,
        address[] memory _subordinates){
            _inviter = userInfo[member].inviter;
            _additionalInviter = userInfo[member].additionalInviter;
            _staking = userInfo[member].staking;
            _property = userInfo[member].property;
            _dailyGrades = userInfo[member].dailyGrades[inviteCurrentTime];
            _weeklyRemove = userInfo[member].weeklyRemove[removeCurrentTime];
            _subordinates = userInfo[member].subordinates;
    }
}


library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

//proxy:0x6b21acf565c6b36B624bc9d4BF006Bd0a2a325AE
//membership:0x1C4722A0e75f1deE91165Cb714F14Af918BAab71
//yzz:0xA3674C9dcaC4909961DF82ecE70fe81aCfCC6F3c
//lp:0x812E9f0E36F4661742E1Ed44Ad27F597953eda8f