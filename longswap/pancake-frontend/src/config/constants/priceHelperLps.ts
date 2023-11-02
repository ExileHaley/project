import tokens from './tokens'
import { SerializedFarmConfig } from './types'

const priceHelperLps: SerializedFarmConfig[] = [
  /**
   * These LPs are just used to help with price calculation for MasterChef LPs (farms.ts).
   * This list is added to the MasterChefLps and passed to fetchFarm. The calls to get contract information about the token/quoteToken in the LP are still made.
   * The absence of a PID means the masterchef contract calls are skipped for this farm.
   * Prices are then fetched for all farms (masterchef + priceHelperLps).
   * Before storing to redux, farms without a PID are filtered out.
   */
  /**
   * 这些 LP 仅用于帮助计算 MasterChef LP (farms.ts) 的价格。
   * 该列表被添加到 MasterChefLps 并传递到 fetchFarm。仍然会调用获取有关 LP 中 token/quoteToken 的合约信息。
   * 缺少 PID 意味着该农场将跳过 masterchef 合约调用。
   * 然后获取所有农场的价格（masterchef + PriceHelperLps）。
   * 在存储到 redux 之前，没有 PID 的农场会被过滤掉。
   */
  {
    pid: null,
    lpSymbol: 'QSD-BNB LP',
    lpAddresses: {
      97: '',
      56: '0x7b3ae32eE8C532016f3E31C8941D937c59e055B9',
    },
    token: tokens.qsd,
    quoteToken: tokens.wbnb,
  },
]

export default priceHelperLps
