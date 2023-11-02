import BigNumber from 'bignumber.js'
import { BLOCKS_PER_YEAR, CAKE_PER_YEAR } from 'config'
import lpAprs from 'config/constants/lpAprs.json'

/**
 * Get the APR value in %
 * @param stakingTokenPrice Token price in the same quote currency
 * @param rewardTokenPrice Token price in the same quote currency
 * @param totalStaked Total amount of stakingToken in the pool
 * @param tokenPerBlock Amount of new cake allocated to the pool for each new block
 * @returns Null if the APR is NaN or infinite.
 */

//接收4个参数
//质押代币的价格
//收益代币的价格
//总质押的数量
//每个区块产生的奖励
export const getPoolApr = (
  stakingTokenPrice: number,
  rewardTokenPrice: number,
  totalStaked: number,
  tokenPerBlock: number,
): number => {
  //它通过将总年度奖励价值（通过将奖励代币价格、每个新块的代币数量和每年的块数相乘计算）
  //除以池中抵押代币的总价值（通过将抵押代币价格和总抵押代币数相乘计算）来计算流动性挖矿池的APR值。
  //结果乘以100转换为百分比。如果APR不是数字或无穷大，则函数返回null
  const totalRewardPricePerYear = new BigNumber(rewardTokenPrice).times(tokenPerBlock).times(BLOCKS_PER_YEAR)
  const totalStakingTokenInPool = new BigNumber(stakingTokenPrice).times(totalStaked)
  const apr = totalRewardPricePerYear.div(totalStakingTokenInPool).times(100)
  return apr.isNaN() || !apr.isFinite() ? null : apr.toNumber()
}

/**
 * Get farm APR value in %
 * @param poolWeight allocationPoint / totalAllocationPoint
 * @param cakePriceUsd Cake price in USD
 * @param poolLiquidityUsd Total pool liquidity in USD
 * @param farmAddress Farm Address
 * @returns Farm Apr
 */
//池子权重
//cake代币的价格
//流动lp的价格
//池子地址
export const getFarmApr = (
  poolWeight: BigNumber,
  cakePriceUsd: BigNumber,
  poolLiquidityUsd: BigNumber,
  farmAddress: string,
): { cakeRewardsApr: number; lpRewardsApr: number } => {
  //它通过将年度Cake奖励分配乘以Cake价格再除以池总流动性价值来计算Cake奖励的APR值。
  //同时，该函数还返回LP奖励的APR值，LP奖励的APR值从预定义的JSON文件中获取。如果APR不是数字或无穷大，则函数返回null
  const yearlyCakeRewardAllocation = poolWeight ? poolWeight.times(CAKE_PER_YEAR) : new BigNumber(NaN)
  const cakeRewardsApr = yearlyCakeRewardAllocation.times(cakePriceUsd).div(poolLiquidityUsd).times(100)
  let cakeRewardsAprAsNumber = null
  if (!cakeRewardsApr.isNaN() && cakeRewardsApr.isFinite()) {
    cakeRewardsAprAsNumber = cakeRewardsApr.toNumber()
  }
  const lpRewardsApr = lpAprs[farmAddress?.toLocaleLowerCase()] ?? 0
  return { cakeRewardsApr: cakeRewardsAprAsNumber, lpRewardsApr }
}

export default null
