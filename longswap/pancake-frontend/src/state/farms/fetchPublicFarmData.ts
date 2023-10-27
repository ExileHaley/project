import BigNumber from 'bignumber.js'
import masterchefABI from 'config/abi/masterchef.json'
import erc20 from 'config/abi/erc20.json'
import { getAddress, getMasterChefAddress } from 'utils/addressHelpers'
import { BIG_TEN, BIG_ZERO } from 'utils/bigNumber'
import multicall from 'utils/multicall'
import { SerializedFarm, SerializedBigNumber } from '../types'

//用来获取池子信息


//定义类型
type PublicFarmData = {
  //序列化的代币总数量
  tokenAmountTotal: SerializedBigNumber
  //LP代币在报价代币中的总价值
  lpTotalInQuoteToken: SerializedBigNumber
  //lp总供应量
  lpTotalSupply: SerializedBigNumber
  //代币相对于报价代币的价格
  tokenPriceVsQuote: SerializedBigNumber
  //池子权重
  poolWeight: SerializedBigNumber
  //倍数，用于奖励
  multiplier: string
}

// 从输入的farm对象中提取了一些关键信息，包括pid（池ID）、LP合约地址、代币信息以及报价代币信息。
const fetchFarm = async (farm: SerializedFarm): Promise<PublicFarmData> => {
  const { pid, lpAddresses, token, quoteToken } = farm
  const lpAddress = getAddress(lpAddresses)
  // 创建了一个包含多个调用的数组，每个调用都是一个对象，描述了要调用的智能合约的地址、函数名以及参数。这些调用包括：

  // 获取LP合约中代币的数量
  // 获取LP合约中报价代币的数量
  // 获取主厨合约中LP代币的数量
  // 获取LP代币的总供应量
  // 获取代币的精度
  // 获取报价代币的精度
  const calls = [
    //获取lp合约中token的数量
    // Balance of token in the LP contract
    {
      address: token.address,
      name: 'balanceOf',
      params: [lpAddress],
    },
    //报价token在lp合约中的数量
    // Balance of quote token on LP contract
    {
      address: quoteToken.address,
      name: 'balanceOf',
      params: [lpAddress],
    },
    //lp在masterchef合约中的数量
    // Balance of LP tokens in the master chef contract
    {
      address: lpAddress,
      name: 'balanceOf',
      params: [getMasterChefAddress()],
    },
    //lp总供应量
    // Total supply of LP tokens
    {
      address: lpAddress,
      name: 'totalSupply',
    },
    //代币精度
    // Token decimals
    {
      address: token.address,
      name: 'decimals',
    },
    //报价代币精度
    // Quote token decimals
    {
      address: quoteToken.address,
      name: 'decimals',
    },
  ]
  // 使用multicall函数来一次性执行这些调用，将结果分配给一系列变量，如tokenBalanceLP、quoteTokenBalanceLP、lpTokenBalanceMC、lpTotalSupply、tokenDecimals和quoteTokenDecimals。
  const [tokenBalanceLP, quoteTokenBalanceLP, lpTokenBalanceMC, lpTotalSupply, tokenDecimals, quoteTokenDecimals] =
    await multicall(erc20, calls)

  // Ratio in % of LP tokens that are staked in the MC, vs the total number in circulation
  //LP代币在主厨合约中的占比，以总供应量为分母。
  const lpTokenRatio = new BigNumber(lpTokenBalanceMC).div(new BigNumber(lpTotalSupply))
  
  // Raw amount of token in the LP, including those not staked
  //代币的总数量，将其从原始值转换为JSON字符串。
  const tokenAmountTotal = new BigNumber(tokenBalanceLP).div(BIG_TEN.pow(tokenDecimals))
  //报价代币的总数量，将其从原始值转换为JSON字符串。
  const quoteTokenAmountTotal = new BigNumber(quoteTokenBalanceLP).div(BIG_TEN.pow(quoteTokenDecimals))

  // Amount of quoteToken in the LP that are staked in the MC
  //在主厨合约中抵押的报价代币数量。
  const quoteTokenAmountMc = quoteTokenAmountTotal.times(lpTokenRatio)

  // Total staked in LP, in quote token value
  //LP代币在报价代币中的总价值，将其从原始值转换为JSON字符串。
  const lpTotalInQuoteToken = quoteTokenAmountMc.times(new BigNumber(2))

  // Only make masterchef calls if farm has pid

  const [info, totalAllocPoint] =
  //如果存在pid或pid等于0，就会调用主厨合约获取更多信息
    pid || pid === 0

      ? await multicall(masterchefABI, [
          { 
            address: getMasterChefAddress(),
            name: 'poolInfo',
            params: [pid],
          },
          {
            address: getMasterChefAddress(),
            name: 'totalAllocPoint',
          },
        ])
      : [null, null]
  //获取池信息，包括分配点数（allocPoint）。
  const allocPoint = info ? new BigNumber(info.allocPoint?._hex) : BIG_ZERO
  //获取主厨合约的总分配点数。
  const poolWeight = totalAllocPoint ? allocPoint.div(new BigNumber(totalAllocPoint)) : BIG_ZERO

  return {
    // 池中代币的总数量，转换为JSON字符串
    tokenAmountTotal: tokenAmountTotal.toJSON(),
    //以报价代币（用于定价池的代币）计价的LP代币的总价值，转换为JSON字符串
    lpTotalSupply: new BigNumber(lpTotalSupply).toJSON(),
    //以报价代币（用于定价池的代币）计价的LP代币的总价值，转换为JSON字符串
    lpTotalInQuoteToken: lpTotalInQuoteToken.toJSON(),
    //一个代币相对于报价代币的价格，通过将报价代币的总价值除以池中代币的总数量计算得出，转换为JSON字符串
    tokenPriceVsQuote: quoteTokenAmountTotal.div(tokenAmountTotal).toJSON(),
    //池在奖励总分配中的权重，转换为JSON字符串
    poolWeight: poolWeight.toJSON(),
    //应用于池分配点数以确定其获得的奖励数量的乘数，转换为附加了“X”的字符串。乘数通过将池的分配点数除以100计算得出。
    multiplier: `${allocPoint.div(100).toString()}X`,
  }
}

export default fetchFarm
