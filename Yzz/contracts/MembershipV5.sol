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

contract StoreV1 is Store{

    enum Target{
        DAILYINVITE,
        WEEKLYINVITE,
        WEEKLYREMOVE,
        LUCKYREWARD,
        HIERARCHY,
        RECOMMEND
    }

    struct Record{
        Target  target;
        address member;
        uint256 amount;
        uint256 time;
    }

    struct Assemble{
        address member;
        uint256 amount;
    }

    struct Whole{
        Target  target;
        uint256 amountRewrad;
        uint256 members;
        uint256 countTime;
    }

    struct User{
        address inviter;
        address additionalInviter;

        uint256 staking;
        uint256 property;

        mapping(uint256 => uint256) dailyInvite;
        mapping(uint256 => uint256) weeklyRemove;
        mapping(uint256 => uint256) weeklyInvite;
        
        address[] inviteForms;
        address[] subordinates;
        Record[]  records;
    }
    mapping(address => User)  userInfo;

    //token
    address public usdt;
    address public token;
    address public lp;

    //address first
    address public leader;

    //swap
    address public uniswapV2Router;
    address public uniswapV2Pair;

    //burn 
    address public dead;

    //lucky
    address[] public fortunes;
    uint256 public lastFortunesTime;

    //Ranking
    //remove Ranking
    mapping(uint256 => address[]) public weeklyRemoveRankings;
    mapping(uint256 => mapping (address => bool)) weeklyRemoveDataAlreadyAdd;
    uint256 public weeklyRemoveCurrentTime;

    //invite Ranking
    mapping(uint256 => address[]) public dailyInviteRankings;
    mapping(uint256 => mapping (address => bool)) dailyInviteDataAlreadyAdd;
    uint256 public dailyInviteCurrentTime;

    //weekly invite rakings
    mapping(uint256 => address[]) public weeklyInviteRankings;
    mapping(uint256 => mapping (address => bool)) weeklyInviteDataAlreadyAdd;
    uint256 public weeklyInviteCurrentTime;

    //data
    uint256 public totalMembers;
    uint256 public totalUsdts;

    //total surplus
    uint256 public surplus;

    //withdraw
    mapping(string => bool) public transactionMark;

    //manager
    address public operator;

    //percent
    mapping(Target => uint256) public percent;
    bool internal  locked;
}

contract MembershipV5 is StoreV1{

    constructor(){
        admin = msg.sender;
    }

    modifier noReentrancy() {
        require(!locked, "Reentrant call detected");
        locked = true;
        _;
        locked = false;
    }

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

    function setOwner(address _owner) external onlyOwner(){
        admin = _owner;
    }

    function setPercent(Target _target,uint256 _percent) external onlyOperator{
        percent[_target] = _percent;
    }
    //token:0x2d0Fd45B5D68A1cBDEE6d9c3B0cF7FF2DF01FDDc
    //lp:0x58a8e508E7F1139075616dC2Ff737C2C6C881838
    //leader:0xB077e40399F1D632F01b6AaAdabcA084E18C4846
    function initialize(address _token,address _lp,address _leader,address _operator) external onlyOwner(){
        token = _token;
        lp = _lp;
        leader = _leader;
        operator = _operator;
        dailyInviteCurrentTime = block.timestamp;
        weeklyInviteCurrentTime = block.timestamp;
        weeklyRemoveCurrentTime = block.timestamp;
        //这里注意调整
        lastFortunesTime = block.timestamp;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        dead = 0x000000000000000000000000000000000000dEaD;
        totalMembers += 1;

        percent[Target.DAILYINVITE] = 5;
        percent[Target.WEEKLYINVITE] = 2;
        percent[Target.WEEKLYREMOVE] = 2;
        percent[Target.LUCKYREWARD] = 1;
    }

    function updateInviteList(address _inviter) internal{
        if(!dailyInviteDataAlreadyAdd[dailyInviteCurrentTime][_inviter] && _inviter != address(0)){
            dailyInviteRankings[dailyInviteCurrentTime].push(_inviter);
            dailyInviteDataAlreadyAdd[dailyInviteCurrentTime][_inviter] = true;
        } 

        if(!weeklyInviteDataAlreadyAdd[weeklyInviteCurrentTime][_inviter] && _inviter != address(0)){
            weeklyInviteRankings[weeklyInviteCurrentTime].push(_inviter);
            weeklyInviteDataAlreadyAdd[weeklyInviteCurrentTime][_inviter] = true;
        }
    }

    function invite(address _inviter, address _member) external{
        if(_inviter != leader) require(userInfo[_inviter].inviter != address(0),"MemberShip: Invalid inviter address");
        require(userInfo[_member].inviter == address(0),"MemberShip: Invalid member address");
        userInfo[_member].additionalInviter = _inviter;
        userInfo[_inviter].inviteForms.push(_member);
        totalMembers += 1;
        updateInviteList(_inviter);
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

    function _addLuidity(uint256 usdtAmount, uint256 tokenAmount) internal returns(uint amountUSDT,uint amountToken,uint luidity){

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

    function _run() internal returns (uint256) {
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        _swapUSDTForToken(balance / 2);
        uint256 amountUSDT = IERC20(usdt).balanceOf(address(this));
        uint256 amountToken = IERC20(token).balanceOf(address(this));
        (, uint _amountToken,uint _luidity)=_addLuidity(amountUSDT, amountToken);
        TransferHelper.safeTransfer(token, dead, amountToken - _amountToken);
        return  _luidity;
    }

    function getAccessAmount(uint256 amount) public view returns(bool supp) {
        uint256 middleDiv = totalMembers / 1000;
        supp = 
            (middleDiv <= 2 && amount == (middleDiv + 1) * 1e20) ||
            (middleDiv >= 3 && amount % 100e18 == 0);
    }


    function getAccessAmountIn() public view returns(uint256 amountIn) {
        uint256 middleDiv = totalMembers / 1000;
        amountIn = (middleDiv <= 2) ? (middleDiv + 1) * 1e20 : 0; 
    }

    function _reward(address member, uint256 amountStake, uint256 amountLP) internal {
        address inviter = userInfo[member].additionalInviter;
        User storage upper = userInfo[inviter];
        upper.dailyInvite[dailyInviteCurrentTime] += amountStake;
        upper.weeklyInvite[weeklyInviteCurrentTime] += amountStake;
        uint256 totalPart = amountLP * 40 / 100;

        if (upper.staking == 0) {
            surplus += totalPart;
        }else if(upper.staking >= amountStake || upper.staking >= 600e18){
            upper.property += totalPart;
            upper.records.push(Record(Target.RECOMMEND,member,totalPart,block.timestamp));
        }else{
            uint256 surplusLP = amountLP / (amountStake / upper.staking) * 40 / 100;
            upper.property += surplusLP;
            upper.records.push(Record(Target.RECOMMEND,member,surplusLP,block.timestamp));
            surplus += (totalPart - surplusLP);
        }
    }

    function _loopReward(address member, uint256 amountStake, uint256 amountLP) internal returns (uint256) {
        address _loop = userInfo[member].inviter;
        uint256 iterations = 0;
        for (uint256 i = 0; i < 50 && _loop != address(0); i++) {
            if (userInfo[_loop].staking > 0) {
                if(userInfo[_loop].staking >= amountStake || userInfo[_loop].staking >= 600e18){
                    userInfo[_loop].property += amountLP * 2 / 1000;
                    userInfo[_loop].records.push(Record(Target.HIERARCHY, member, amountLP * 2 / 1000, block.timestamp));
                }else{
                    uint256 surplusLP = amountLP / (amountStake / userInfo[_loop].staking) * 2 / 1000;
                    userInfo[_loop].property += surplusLP;
                    userInfo[_loop].records.push(Record(Target.HIERARCHY, member, surplusLP, block.timestamp));
                    surplus += (amountLP * 2 / 1000 - surplusLP);
                }
            } else {
                surplus += amountLP * 2 / 1000;
            }
            _loop = userInfo[_loop].inviter;
            iterations = i + 1;
        }
        return iterations;
    }



    function provide(address member, uint256 amount) external noReentrancy{
        User storage user = userInfo[member];
        if(member != leader) require(user.inviter != address(0),"Membership: Invalid inviter address");
        require(getAccessAmount(amount),"Membership: Invalid provide amount");
        if(getAccessAmountIn() > 0) require(getAccessAmountIn() - user.staking >= amount,"Membership:No over-participation allowed");
        TransferHelper.safeTransferFrom(usdt, member, address(this), amount); 
        require(IERC20(usdt).balanceOf(address(this)) >= amount, "Membership: Insufficient token balance");
        user.staking += amount;
        uint256 _luidity = _run();
        user.property += _luidity * 40 / 100;
        totalUsdts += amount;
        userInfo[user.additionalInviter].dailyInvite[dailyInviteCurrentTime] += amount;
        userInfo[user.additionalInviter].dailyInvite[weeklyInviteCurrentTime] += amount;
        _reward(member,amount,_luidity);

        uint256 index = _loopReward(member, amount, _luidity);
        uint256 hierarchy = _luidity * 20 / 100;
        uint256 pre = _luidity * 2 / 1000;
        surplus = surplus + (hierarchy - pre * index);

        _distributeLuckyReward(member);
    }

    function _distributeLuckyReward(address member) internal{

        if(totalMembers == 2) lastFortunesTime = block.timestamp + 86400;

        if(block.timestamp >= lastFortunesTime && fortunes.length > 0){
            uint256 totalReward = surplus * percent[Target.LUCKYREWARD] / 100;
            userInfo[fortunes[fortunes.length - 1]].property += (totalReward / 2);
            userInfo[fortunes[fortunes.length - 1]].records.push(Record(Target.LUCKYREWARD, leader, totalReward / 2, block.timestamp));
            surplus -= totalReward / 2;
            lastFortunesTime = block.timestamp + 86400;
        }else{
            lastFortunesTime = block.timestamp + 3600;
        }
        fortunes.push(member);
    }

    function withdraw(address member,uint256 amount) external{
        require(userInfo[member].property >= amount,"MemberShip: Invalid withdraw lp`s amount");
        userInfo[member].property -= amount;
        TransferHelper.safeTransfer(lp, member, amount);
    }

    function managerWithdraw(address target,address receiver) external onlyOperator(){
        uint256 total = IERC20(target).balanceOf(address(this));
        TransferHelper.safeTransfer(target, receiver, total);
    }

    function removeLuidity(address member, uint256 amount) external {
        User storage user = userInfo[member];
        require(user.property >= amount,"MemberShip: Invalid remove lp`s amount!");
        uint256 targetAmount = amount * 97 / 100;
        user.property -= amount;
        surplus += (amount - targetAmount);
        user.weeklyRemove[weeklyRemoveCurrentTime] += amount;
        if (!weeklyRemoveDataAlreadyAdd[weeklyRemoveCurrentTime][member]) {
            weeklyRemoveRankings[weeklyRemoveCurrentTime].push(member);
            weeklyRemoveDataAlreadyAdd[weeklyRemoveCurrentTime][member] = true;
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

    function getLuckyRankings() external view returns(address[] memory lucky, uint256 lastTime,uint256 count) {
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
        if(block.timestamp >= lastFortunesTime) count = 0;
        else count = lastFortunesTime - block.timestamp;
    }

    function getRankings(Target target) external view returns(address[] memory){
        if (Target.DAILYINVITE == target) return dailyInviteRankings[dailyInviteCurrentTime];
        else if(Target.WEEKLYINVITE == target) return weeklyInviteRankings[weeklyInviteCurrentTime];
        else if(Target.WEEKLYREMOVE == target) return weeklyRemoveRankings[weeklyRemoveCurrentTime];
        else return new address[](0);
    }

    function getMemberGrades(Target target,address member) external view returns(uint256){
        if (target == Target.DAILYINVITE) return userInfo[member].dailyInvite[dailyInviteCurrentTime];
        else if(target == Target.WEEKLYINVITE) return userInfo[member].weeklyInvite[weeklyInviteCurrentTime];
        else if(target == Target.WEEKLYREMOVE) return userInfo[member].weeklyRemove[weeklyRemoveCurrentTime];
        else return 0;
    }

    function multiGetMemberGrades(Target target,address[] memory member) external view returns(Assemble[] memory){
        Assemble[] memory grades = new Assemble[](member.length);
        if (target == Target.DAILYINVITE){
            for(uint i=0; i<grades.length; i++){
                grades[i] = Assemble(member[i],userInfo[member[i]].dailyInvite[dailyInviteCurrentTime]);
            }
        }

        if (target == Target.WEEKLYREMOVE){
            for(uint i=0; i<grades.length; i++){
                grades[i] = Assemble(member[i],userInfo[member[i]].weeklyRemove[weeklyRemoveCurrentTime]);
            }
        }

        if (target == Target.WEEKLYINVITE){
            for(uint i=0; i<grades.length; i++){
                grades[i] = Assemble(member[i],userInfo[member[i]].weeklyInvite[weeklyInviteCurrentTime]);
            }
        }
        return grades;
    }

    function getWholeInfo() external view returns(Whole[] memory){
        Whole[] memory wholes = new  Whole[](4);
        uint256 dailyInviteCount;
        uint256 weeklyInviteCount;
        uint256 weeklyRemoveCount;
        if(dailyInviteCurrentTime + 86400 > block.timestamp) {
            dailyInviteCount = dailyInviteCurrentTime + 86400 - block.timestamp;
        }
        if(weeklyInviteCurrentTime + 86400 > block.timestamp){
            weeklyInviteCount =  weeklyInviteCurrentTime + 86400 - block.timestamp;
        }
        if(weeklyRemoveCurrentTime + 86400 > block.timestamp){
            weeklyRemoveCount =  weeklyRemoveCurrentTime + 86400 - block.timestamp;
        }
        wholes[0] = Whole(Target.DAILYINVITE, surplus * 5 / 100, dailyInviteRankings[dailyInviteCurrentTime].length, dailyInviteCount);
        wholes[1] = Whole(Target.WEEKLYINVITE, surplus * 2 / 100, weeklyInviteRankings[weeklyInviteCurrentTime].length,weeklyInviteCount);
        wholes[2] = Whole(Target.WEEKLYREMOVE, surplus * 2 / 100, weeklyRemoveRankings[weeklyRemoveCurrentTime].length,weeklyRemoveCount);
        wholes[3] = Whole(Target.LUCKYREWARD, surplus / 100, 0, 0);
        return wholes;
    }

    function getUserInfo(address member) external view returns(
        uint256 _dailyInvite, 
        uint256 _weeklyRemove,
        uint256 _weeklyInvite,
        address[] memory _inviteForms,
        address[] memory _subordinates,
        Record[] memory _records
    ){
        _dailyInvite = userInfo[member].dailyInvite[dailyInviteCurrentTime];
        _weeklyRemove = userInfo[member].weeklyRemove[weeklyRemoveCurrentTime];
        _weeklyInvite = userInfo[member].weeklyInvite[weeklyInviteCurrentTime];
        _inviteForms = userInfo[member].inviteForms;
        _subordinates = userInfo[member].subordinates;
        _records = userInfo[member].records;

    }

    function getBaseUserInfo(address member) external view returns(address _inviter,address _additionalInviter,uint256 _staking,uint256 _property){
        _inviter = userInfo[member].inviter;
        _additionalInviter = userInfo[member].additionalInviter;
        _staking = userInfo[member].staking;
        _property = userInfo[member].property;
    }

    function distributeRankings(address[] memory members,Target target,string memory mark) external onlyOperator(){
        if (Target.DAILYINVITE == target) dailyInviteCurrentTime = block.timestamp;
        if(Target.WEEKLYINVITE == target) weeklyInviteCurrentTime = block.timestamp;
        if(Target.WEEKLYREMOVE == target) weeklyRemoveCurrentTime = block.timestamp;
        require(percent[target] > 0,"Membership:Invalid percent!");
        uint256 totalReward = surplus * percent[target] / 100;
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
            userInfo[members[i]].records.push(Record(target, leader, share, block.timestamp));
            surplus -= share;
        }
        transactionMark[mark] = true;
    }

    function getLuidityPrice(uint256 amount) external view returns(uint256){
        uint256 amountUSDT = IERC20(usdt).balanceOf(uniswapV2Pair);
        uint256 amountLP = IERC20(lp).totalSupply();
        return amountUSDT * amount / amountLP;
    }


}

//proxy:0x44df0800a6d0fA4b5Ad207B34Ba7050aF5E287Fe
//membership:0xc2d12eA250f4fF972D19Ab0641Bbf5eDFb4340d3
//yzz:0x2d0Fd45B5D68A1cBDEE6d9c3B0cF7FF2DF01FDDc
//lp:0x58a8e508E7F1139075616dC2Ff737C2C6C881838