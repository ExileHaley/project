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
        PROSPER,
        EARLYBIRD
    }

    struct Assemble{
        address member;
        uint256 amount;
    }

    struct Prize{
        Target target;
        uint256 amount;
    }

    struct User{
        address inviter;
        address additionalInviter;
        //1707066288
        //1707069888
        uint256 staking;
        uint256 property;

        mapping(uint256 => uint256) dailyInvite;
        mapping(uint256 => uint256) weeklyRemove;
        mapping(uint256 => uint256) weeklyInvite;
        
        address[] inviteForms;
        address[] subordinates;
        
    }
    mapping(address => User)  userInfo;

    //token
    address usdt;
    address token;
    address lp;

    //address first
    address public leader;

    //swap
    address uniswapV2Router;

    //burn 
    address dead;

    //lucky
    address[] prosperDefense;
    uint256 lastProsperDefenseUpdateTime;

    //remove list
    address[] earlyBirdDefense;
    uint256 lastEarlyBirdDefenseUpdateTime;

    //Ranking
    //remove Ranking
    mapping(uint256 => address[]) weeklyRemoveRankings;
    mapping(uint256 => mapping (address => bool)) weeklyRemoveDataAlreadyAdd;
    uint256 public weeklyRemoveCurrentTime;

    //invite Ranking
    mapping(uint256 => address[]) dailyInviteRankings;
    mapping(uint256 => mapping (address => bool)) dailyInviteDataAlreadyAdd;
    uint256 public dailyInviteCurrentTime;

    //weekly invite rakings
    mapping(uint256 => address[]) weeklyInviteRankings;
    mapping(uint256 => mapping (address => bool)) weeklyInviteDataAlreadyAdd;
    uint256 public weeklyInviteCurrentTime;

    //data
    uint256 public totalMembers;
    uint256 totalUsdts;

    //total surplus
    uint256 public totalSurplus;

    //withdraw
    mapping(string => bool) public transactionMark;

    //manager
    address public operator;

    //percent
    mapping(Target => uint256) percent;
    bool  locked;

    //rewards
    uint256 dailyInviteCurrentSurplus;
    uint256 weeklyInviteCurrentSurplus;
    uint256 weeklyRemoveCurrentSurplus;
    uint256 prosperCurrentSurplus;
    uint256 earlyBirdCurrentSurplus;

    //limit remove
    uint256 positiveRemove;
}

contract MembershipV9 is StoreV1{

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

    function managerWithdraw(address _token, address _to, uint256 _amount) external onlyOperator(){
        TransferHelper.safeTransfer(_token, _to, _amount);
    }

    function setMinPositiveRemove(uint256 amount) external onlyOperator(){
        positiveRemove = amount;
    }

    // function initialize(address _token,address _lp,address _leader,address _operator) external onlyOwner(){
    //     token = _token;
    //     lp = _lp;
    //     leader = _leader;
    //     operator = _operator;
    //     dailyInviteCurrentTime = block.timestamp;
    //     weeklyInviteCurrentTime = block.timestamp;
    //     weeklyRemoveCurrentTime = block.timestamp;
    //     usdt = 0x55d398326f99059fF775485246999027B3197955;
    //     uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //     dead = 0x000000000000000000000000000000000000dEaD;
    //     totalMembers += 1;
    //     positiveRemove = 10e18;
    //     percent[Target.DAILYINVITE] = 5;
    //     percent[Target.WEEKLYINVITE] = 1;
    //     percent[Target.WEEKLYREMOVE] = 2;
    //     percent[Target.PROSPER] = 1;
    //     percent[Target.EARLYBIRD] = 1;
    // }

    function initialize() external onlyOwner(){
        dailyInviteCurrentSurplus = 23765e18;
        weeklyInviteCurrentSurplus = 12000e18;
        prosperCurrentSurplus = 12000e18;
        earlyBirdCurrentSurplus = 12000e18;
        weeklyRemoveCurrentSurplus = 24000e18;
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
        require(_member == msg.sender && _inviter != _member,"MemberShip:Member address error!");
        if(_inviter != leader) require(userInfo[_inviter].inviter != address(0) && userInfo[_inviter].staking > 0, "MemberShip: Invalid inviter address");
        require(userInfo[_member].inviter == address(0) && userInfo[_member].additionalInviter == address(0), "MemberShip: Invalid member address");
        userInfo[_member].additionalInviter = _inviter;
        userInfo[_inviter].inviteForms.push(_member);
        totalMembers += 1;
        updateInviteList(_inviter);
        iterativeInvite(_inviter, _member);
    }
////////////////////////////////////////////////////invite/////////////////////////////////////////////////////////////////

    function iterativeInvite(address _inviter, address _member) internal  {
        address[] memory currentLayer = new address[](1);
        currentLayer[0] = _inviter;
        for (uint8 layer = 0; layer < 10; layer++) { 
            address[] memory nextLayer = new address[](currentLayer.length * 2);
            uint256 nextLayerIndex = 0;

            for (uint256 i = 0; i < currentLayer.length; i++) {
                address inviter = currentLayer[i];
                if (userInfo[inviter].subordinates.length >= 2) {
                    for (uint256 j = 0; j < userInfo[inviter].subordinates.length; j++) {
                        nextLayer[nextLayerIndex] = userInfo[inviter].subordinates[j];
                        nextLayerIndex++;
                    }
                } else {
                    userInfo[_member].inviter = inviter;
                    userInfo[inviter].subordinates.push(_member);
                    return;
                }
            }
            currentLayer = nextLayer;
        }
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

    function _reward(address member, uint256 amountStake, uint256 amountLP) internal returns(uint256){
        address inviter = userInfo[member].additionalInviter;
        User storage upper = userInfo[inviter];
        upper.dailyInvite[dailyInviteCurrentTime] += amountStake;
        upper.weeklyInvite[weeklyInviteCurrentTime] += amountStake;
        uint256 totalPart = amountLP * 40 / 100;

        if (upper.staking == 0) {
            return totalPart;
        }else if(upper.staking >= amountStake || upper.staking >= 300e18){
            upper.property += totalPart;
            TransferHelper.safeTransfer(lp, inviter, totalPart);
            return 0;
        }else{
            uint256 surplusLP = amountLP / (amountStake / upper.staking) * 40 / 100;
            upper.property += surplusLP;
            TransferHelper.safeTransfer(lp, inviter, surplusLP);
            return (totalPart - surplusLP);
        }
    }

    function _loopReward(address member, uint256 amountStake, uint256 amountLP) internal returns (uint256 iterations,uint256 total) {
        address _loop = userInfo[member].inviter;
        for (uint256 i = 0; i < 50 && _loop != address(0); i++) {
            if (userInfo[_loop].staking > 0) {
                if(userInfo[_loop].staking >= amountStake || userInfo[_loop].staking >= 300e18){
                    userInfo[_loop].property += amountLP * 2 / 1000;
                    TransferHelper.safeTransfer(lp, _loop, amountLP * 2 / 1000);
                }else{
                    uint256 surplusLP = amountLP / (amountStake / userInfo[_loop].staking) * 2 / 1000;
                    userInfo[_loop].property += surplusLP;
                    TransferHelper.safeTransfer(lp, _loop, surplusLP);
                    total += (amountLP * 2 / 1000 - surplusLP);
                }
            } else {
                total += amountLP * 2 / 1000;
            }
            _loop = userInfo[_loop].inviter;
            iterations = i + 1;
        }
    }

    function updateRewards(uint256 luidity) internal{
        dailyInviteCurrentSurplus += (luidity * percent[Target.DAILYINVITE] / 100);
        weeklyInviteCurrentSurplus += (luidity * percent[Target.WEEKLYINVITE] / 100);
        weeklyRemoveCurrentSurplus += (luidity * percent[Target.WEEKLYREMOVE] / 100);
        prosperCurrentSurplus += (luidity * percent[Target.PROSPER] / 100);
        earlyBirdCurrentSurplus += (luidity * percent[Target.EARLYBIRD] / 100);
    }

    function updateCountTime(Target target) internal {
        if(Target.PROSPER == target){
            if(lastProsperDefenseUpdateTime > block.timestamp){
                uint256 totalMiddle = lastProsperDefenseUpdateTime - block.timestamp;
                if (86400 - totalMiddle <= 3600) lastProsperDefenseUpdateTime = block.timestamp + 86400;
                else  lastProsperDefenseUpdateTime += 3600;
            }
        }

        if(Target.EARLYBIRD == target){
            if(lastEarlyBirdDefenseUpdateTime > block.timestamp){
                uint256 totalMiddle = lastEarlyBirdDefenseUpdateTime - block.timestamp;
                if (86400 - totalMiddle <= 600) lastEarlyBirdDefenseUpdateTime = block.timestamp + 86400;
                else  lastEarlyBirdDefenseUpdateTime += 600;
            }
        }
    }


    function _distributeProsperReward(address member) internal{
        if(lastProsperDefenseUpdateTime == 0) lastProsperDefenseUpdateTime = block.timestamp + 86400;
        if(block.timestamp >= lastProsperDefenseUpdateTime && prosperDefense.length > 0){
            userInfo[prosperDefense[prosperDefense.length - 1]].property += ( prosperCurrentSurplus / 2 );
            TransferHelper.safeTransfer(lp, prosperDefense[prosperDefense.length - 1], prosperCurrentSurplus / 2);
            lastProsperDefenseUpdateTime = block.timestamp + 86400;
            prosperCurrentSurplus = (prosperCurrentSurplus/2);
        }
        prosperDefense.push(member);
        updateCountTime(Target.PROSPER);
    }

    function _distributeEarlyBirdReward(address member,uint256 amount) internal{
        if(lastEarlyBirdDefenseUpdateTime == 0) lastEarlyBirdDefenseUpdateTime = block.timestamp + 86400;
        if(block.timestamp >= lastEarlyBirdDefenseUpdateTime && earlyBirdDefense.length > 0){
            userInfo[earlyBirdDefense[earlyBirdDefense.length - 1]].property += ( earlyBirdCurrentSurplus / 2 );
            TransferHelper.safeTransfer(lp, earlyBirdDefense[earlyBirdDefense.length - 1], earlyBirdCurrentSurplus / 2);
            lastEarlyBirdDefenseUpdateTime = block.timestamp + 86400;
            earlyBirdCurrentSurplus = (earlyBirdCurrentSurplus / 2);
        }
        updateCountTime(Target.EARLYBIRD);
        if(amount >= positiveRemove) earlyBirdDefense.push(member);
    }

    function provide(address member, uint256 amount) external noReentrancy{
        User storage user = userInfo[member];
        require(user.inviter != address(0),"Membership: Invalid inviter address");
        require(amount % 100e18 == 0,"Invalid provide amount!");
        TransferHelper.safeTransferFrom(usdt, member, address(this), amount); 
        require(IERC20(usdt).balanceOf(address(this)) >= amount, "Membership: Insufficient token balance");
        user.staking += amount;
        uint256 _luidity = _run();
        user.property += _luidity * 40 / 100;
        TransferHelper.safeTransfer(lp, member, _luidity * 40 / 100);
        totalUsdts += amount;
        
        uint256 recommecndSurplus = _reward(member,amount,_luidity);
        (uint256 index, uint256 total) = _loopReward(member, amount, _luidity);
        uint256 hierarchy = _luidity * 20 / 100;
        uint256 pre = _luidity * 2 / 1000;

        uint256 currentSurplus = (hierarchy - pre * index) + recommecndSurplus + total;
        totalSurplus += currentSurplus;
        _distributeProsperReward(member);
        updateRewards(currentSurplus);
    }


    function removeLuidity(address member, uint256 amount)external {
        require(member == msg.sender,"Membership:Not permit!");
        TransferHelper.safeTransferFrom(lp, member, address(this), amount);
        uint256 _removeAmount = amount * 97 / 100;
        totalSurplus += (amount * 3 / 100);
        updateRewards(amount * 3 / 100);
        _distributeEarlyBirdReward(member,amount);
        _removeLuidity(member, amount, _removeAmount);
    }

    function _removeLuidity(address member, uint256 original, uint256 amount) internal {

        userInfo[member].weeklyRemove[weeklyRemoveCurrentTime] += original;

        if (!weeklyRemoveDataAlreadyAdd[weeklyRemoveCurrentTime][member]) {
            weeklyRemoveRankings[weeklyRemoveCurrentTime].push(member);
            weeklyRemoveDataAlreadyAdd[weeklyRemoveCurrentTime][member] = true;
        }

        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = token;
        IERC20(lp).approve(uniswapV2Router, amount);
        IUniswapV2Router(uniswapV2Router).removeLiquidity(
            token, 
            usdt, 
            amount, 
            0, 
            0, 
            member, 
            block.timestamp + 10
        );
    }

    function getProsperOrEarlyBirdInfo(Target target) external view returns(address last, uint256 lastTime,uint256 count) {
        if(target == Target.PROSPER){
            if (prosperDefense.length > 0) last = prosperDefense[prosperDefense.length - 1];
            lastTime = lastProsperDefenseUpdateTime;
            if(block.timestamp >= lastProsperDefenseUpdateTime) count = 0;
            else count = lastProsperDefenseUpdateTime - block.timestamp;
        }

        if(target == Target.EARLYBIRD){
            if (earlyBirdDefense.length > 0) last = earlyBirdDefense[earlyBirdDefense.length - 1];
            lastTime = lastEarlyBirdDefenseUpdateTime;
            if(block.timestamp >= lastEarlyBirdDefenseUpdateTime) count = 0;
            else count = lastEarlyBirdDefenseUpdateTime - block.timestamp;
        }
        
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


    function getUserInfo(address member) external view returns(
        uint256 _dailyInvite, 
        uint256 _weeklyRemove,
        uint256 _weeklyInvite,
        address[] memory _inviteForms,
        address[] memory _subordinates
    ){
        _dailyInvite = userInfo[member].dailyInvite[dailyInviteCurrentTime];
        _weeklyRemove = userInfo[member].weeklyRemove[weeklyRemoveCurrentTime];
        _weeklyInvite = userInfo[member].weeklyInvite[weeklyInviteCurrentTime];
        _inviteForms = userInfo[member].inviteForms;
        _subordinates = userInfo[member].subordinates;
    }

    function getBaseUserInfo(address member) external view returns(address _inviter,address _additionalInviter,uint256 _staking,uint256 _property){
        _inviter = userInfo[member].inviter;
        _additionalInviter = userInfo[member].additionalInviter;
        _staking = userInfo[member].staking;
        _property = userInfo[member].property;
    }

    function getLuidityPrice(uint256 amount) external view returns(uint256){
        uint256 amountUSDT = IERC20(usdt).balanceOf(lp);
        uint256 amountLP = IERC20(lp).totalSupply();
        return amountUSDT * amount/ amountLP;
    }

    function updateSurplus() internal{
        uint256 total = IERC20(lp).balanceOf(address(this));
        uint256 spend = dailyInviteCurrentSurplus + weeklyInviteCurrentSurplus + weeklyRemoveCurrentSurplus + 
                            prosperCurrentSurplus + earlyBirdCurrentSurplus;
        if(total >= spend){
            uint256 middle = total - spend;
            dailyInviteCurrentSurplus = (middle * percent[Target.DAILYINVITE] / 100);
            weeklyInviteCurrentSurplus += (middle * percent[Target.WEEKLYINVITE] / 100);
            weeklyRemoveCurrentSurplus += (middle * percent[Target.WEEKLYREMOVE] / 100);
            prosperCurrentSurplus += (middle * percent[Target.PROSPER] / 100);
            earlyBirdCurrentSurplus += (middle * percent[Target.EARLYBIRD] / 100);
        }
    }

    function updatePrizes(Target target) internal{
        if (Target.DAILYINVITE == target) {
            dailyInviteCurrentTime = block.timestamp;
            totalSurplus = 0;
            updateSurplus();
        }
        if (Target.WEEKLYINVITE == target) {
            weeklyInviteCurrentTime = block.timestamp;
            weeklyInviteCurrentSurplus = 0;
        }
        if (Target.WEEKLYREMOVE == target) {
            weeklyRemoveCurrentTime = block.timestamp;
            weeklyRemoveCurrentSurplus = 0;
        }
    }

    function getPrizeInfo() public view returns(Prize[] memory){
        Prize[] memory prizes = new Prize[](5);
        prizes[0] = Prize(Target.DAILYINVITE,dailyInviteCurrentSurplus);
        prizes[1] = Prize(Target.WEEKLYINVITE,weeklyInviteCurrentSurplus);
        prizes[2] = Prize(Target.WEEKLYREMOVE,weeklyRemoveCurrentSurplus);
        prizes[3] = Prize(Target.PROSPER, prosperCurrentSurplus);
        prizes[4] = Prize(Target.EARLYBIRD, earlyBirdCurrentSurplus);
        return prizes;
    }

    function prizesInfo(Target target) internal view returns(uint256){
        Prize[] memory prizes = getPrizeInfo();
        if (Target.DAILYINVITE == target) {
            return prizes[0].amount;
        }
        if (Target.WEEKLYINVITE == target) {
            return prizes[1].amount;
        }
        if (Target.WEEKLYREMOVE == target) {
            return prizes[2].amount;
        }

        if (Target.PROSPER == target){
            return prizes[3].amount;
        }

        if (Target.EARLYBIRD == target){
            return prizes[4].amount;
        }
        return 0;
    }

    function distributeRankings(address[] memory members,Target target,string memory mark) external onlyOperator(){
        uint256 rewards = prizesInfo(target);
        require(rewards > 0,"Membership:Invalid percent!");
        uint256 thirtyPercent = rewards * 30 / 100;
        uint256 twentyPercent = rewards * 20 / 100;
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
            TransferHelper.safeTransfer(lp, members[i], share);
        }
        transactionMark[mark] = true;
        updatePrizes(target);
    }

    function getTruthSurplus() external view returns(uint256){
        return IERC20(lp).balanceOf(address(this));
    }
    
}


//online version2.0
//yzz:0xc71b934E6DC876A3B6Fbc7A2FF3394915Bcac51B
//lp:0x6b78C08452FACDf8C52803d74FaB51f31B61a32e
//leader:0x6A2F07083CA1F09700C237Bc699821012506c05A
//permit:0x8EC1Cd137898008f50A623EF418D6eda5CE25052
//proxy:0x1a3B98c59059480eE21eFb3b7d98B640B112470C
//membership:0xec271ca11AD2a4fC54655e9ABDa694b6Eba1213f