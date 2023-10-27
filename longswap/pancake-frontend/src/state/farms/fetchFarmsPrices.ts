import BigNumber from 'bignumber.js'
import { BIG_ONE, BIG_ZERO } from 'utils/bigNumber'
import { filterFarmsByQuoteToken } from 'utils/farmsPriceHelpers'
import { SerializedFarm } from 'state/types'
import tokens from 'config/constants/tokens'

// 这个函数接受三个参数：farms（农场列表数组）、tokenSymbol（代币符号字符串）和preferredQuoteTokens（可选的报价代币列表）。
// 首先，它过滤出包含特定代币符号的农场，并将结果存储在farmsWithTokenSymbol中。
// 然后，它调用 filterFarmsByQuoteToken 函数，根据 preferredQuoteTokens 进一步筛选这些农场。
// 最后，它返回筛选后的农场对象，这个农场对象是一个 SerializedFarm 类型。
const getFarmFromTokenSymbol = (
  farms: SerializedFarm[],
  tokenSymbol: string,
  preferredQuoteTokens?: string[],
): SerializedFarm => {
  const farmsWithTokenSymbol = farms.filter((farm) => farm.token.symbol === tokenSymbol)
  const filteredFarm = filterFarmsByQuoteToken(farmsWithTokenSymbol, preferredQuoteTokens)
  return filteredFarm
}

// 这个函数用于获取农场中基础代币的价格。
// 它接受三个参数：farm（农场对象）、quoteTokenFarm（报价代币对应的农场对象）和 bnbPriceBusd（BNB相对于BUSD的价格）。
// 首先，它检查 farm 是否具有 tokenPriceVsQuote 字段，并将结果存储在 hasTokenPriceVsQuote 变量中。
// 接着，它根据 quoteToken 的符号执行不同的计算，包括：
// 如果 quoteToken 的符号是 'BUSD'，则直接返回 farm.tokenPriceVsQuote，或者零（BIG_ZERO）如果 hasTokenPriceVsQuote 为假。
// 如果 quoteToken 的符号是 'WBNB'，则返回 bnbPriceBusd 乘以 farm.tokenPriceVsQuote，或者零（BIG_ZERO）如果 hasTokenPriceVsQuote 为假。
// 如果 quoteToken 不是 'BUSD' 或 'WBNB'，则会检查 quoteTokenFarm，并计算代币价格，使其以 'BUSD' 为报价代币的价格计价。
const getFarmBaseTokenPrice = (
  farm: SerializedFarm,
  quoteTokenFarm: SerializedFarm,
  bnbPriceBusd: BigNumber,
): BigNumber => {
  const hasTokenPriceVsQuote = Boolean(farm.tokenPriceVsQuote)

  if (farm.quoteToken.symbol === tokens.busd.symbol) {
    return hasTokenPriceVsQuote ? new BigNumber(farm.tokenPriceVsQuote) : BIG_ZERO
  }

  if (farm.quoteToken.symbol === tokens.wbnb.symbol) {
    return hasTokenPriceVsQuote ? bnbPriceBusd.times(farm.tokenPriceVsQuote) : BIG_ZERO
  }

  // We can only calculate profits without a quoteTokenFarm for BUSD/BNB farms
  if (!quoteTokenFarm) {
    return BIG_ZERO
  }

  // Possible alternative farm quoteTokens:
  // UST (i.e. MIR-UST), pBTC (i.e. PNT-pBTC), BTCB (i.e. bBADGER-BTCB), ETH (i.e. SUSHI-ETH)
  // If the farm's quote token isn't BUSD or WBNB, we then use the quote token, of the original farm's quote token
  // i.e. for farm PNT - pBTC we use the pBTC farm's quote token - BNB, (pBTC - BNB)
  // from the BNB - pBTC price, we can calculate the PNT - BUSD price
  if (quoteTokenFarm.quoteToken.symbol === tokens.wbnb.symbol) {
    const quoteTokenInBusd = bnbPriceBusd.times(quoteTokenFarm.tokenPriceVsQuote)
    return hasTokenPriceVsQuote && quoteTokenInBusd
      ? new BigNumber(farm.tokenPriceVsQuote).times(quoteTokenInBusd)
      : BIG_ZERO
  }

  if (quoteTokenFarm.quoteToken.symbol === tokens.busd.symbol) {
    const quoteTokenInBusd = quoteTokenFarm.tokenPriceVsQuote
    return hasTokenPriceVsQuote && quoteTokenInBusd
      ? new BigNumber(farm.tokenPriceVsQuote).times(quoteTokenInBusd)
      : BIG_ZERO
  }

  // Catch in case token does not have immediate or once-removed BUSD/WBNB quoteToken
  return BIG_ZERO
}

// 这个函数用于获取农场中报价代币的价格。
// 它接受三个参数：farm（农场对象）、quoteTokenFarm（报价代币对应的农场对象）和 bnbPriceBusd（BNB相对于BUSD的价格）。
// 根据 quoteToken 的符号执行不同的计算，包括：
// 如果 quoteToken 的符号是 'BUSD'，则直接返回 BIG_ONE，表示报价代币的价格为1。
// 如果 quoteToken 的符号是 'WBNB'，则返回 bnbPriceBusd，表示报价代币的价格等于 bnbPriceBusd。
// 如果 quoteToken 不是 'BUSD' 或 'WBNB'，则会检查 quoteTokenFarm，并计算报价代币价格，使其以 'BUSD' 为报价代币的价格计价。
const getFarmQuoteTokenPrice = (
  farm: SerializedFarm,
  quoteTokenFarm: SerializedFarm,
  bnbPriceBusd: BigNumber,
): BigNumber => {
  if (farm.quoteToken.symbol === 'BUSD') {
    return BIG_ONE
  }

  if (farm.quoteToken.symbol === 'WBNB') {
    return bnbPriceBusd
  }

  if (!quoteTokenFarm) {
    return BIG_ZERO
  }

  if (quoteTokenFarm.quoteToken.symbol === 'WBNB') {
    return quoteTokenFarm.tokenPriceVsQuote ? bnbPriceBusd.times(quoteTokenFarm.tokenPriceVsQuote) : BIG_ZERO
  }

  if (quoteTokenFarm.quoteToken.symbol === 'BUSD') {
    return quoteTokenFarm.tokenPriceVsQuote ? new BigNumber(quoteTokenFarm.tokenPriceVsQuote) : BIG_ZERO
  }

  return BIG_ZERO
}

// 这个函数接受一个农场列表 farms 作为参数。
// 首先，它从 farms 列表中找到一个特定的农场（bnbBusdFarm），其 pid 为252。然后计算 bnbPriceBusd，它是 BNB 相对于 BUSD 的价格。
// 接下来，它对每个农场进行循环遍历，并使用 getFarmBaseTokenPrice 和 getFarmQuoteTokenPrice 函数来计算基础代币和报价代币的价格。
// 最后，将计算后的价格信息添加到每个农场对象中，并返回包含价格信息的更新后的农场列表。
const fetchFarmsPrices = async (farms: SerializedFarm[]) => {
  const bnbBusdFarm = farms.find((farm) => farm.pid === 252)
  const bnbPriceBusd = bnbBusdFarm.tokenPriceVsQuote ? BIG_ONE.div(bnbBusdFarm.tokenPriceVsQuote) : BIG_ZERO

  const farmsWithPrices = farms.map((farm) => {
    const quoteTokenFarm = getFarmFromTokenSymbol(farms, farm.quoteToken.symbol)
    const tokenPriceBusd = getFarmBaseTokenPrice(farm, quoteTokenFarm, bnbPriceBusd)
    const quoteTokenPriceBusd = getFarmQuoteTokenPrice(farm, quoteTokenFarm, bnbPriceBusd)

    return {
      ...farm,
      tokenPriceBusd: tokenPriceBusd.toJSON(),
      quoteTokenPriceBusd: quoteTokenPriceBusd.toJSON(),
    }
  })

  return farmsWithPrices
}

export default fetchFarmsPrices
