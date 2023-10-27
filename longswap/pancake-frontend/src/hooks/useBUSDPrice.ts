import { ChainId, Currency, currencyEquals, JSBI, Price } from '@pancakeswap/sdk'
import tokens, { mainnetTokens } from 'config/constants/tokens'
import useActiveWeb3React from 'hooks/useActiveWeb3React'
import { useMemo } from 'react'
import { multiplyPriceByAmount } from 'utils/prices'
import { wrappedCurrency } from '../utils/wrappedCurrency'
import { PairState, usePairs } from './usePairs'




const BUSD_MAINNET = mainnetTokens.busd
const { wbnb: WBNB } = tokens

/**
 * Returns the price in BUSD of the input currency
 * @param currency currency to compute the BUSD price of
 */
//TODO
//传入代币返回对应的busd价格

// 函数useBUSDPrice：

// 接受一个名为currency的可选参数，代表要计算BUSD价格的代币。
// 接下来的逻辑是根据代币类型不同来计算BUSD价格：



// 
export default function useBUSDPrice(currency?: Currency): Price | undefined {
  //得到chainId
  const { chainId } = useActiveWeb3React()
  //通过代币和链ID获取
  // 使用wrappedCurrency函数将currency和chainId作为参数，获取wrapped，这个wrapped表示包装后的代币。
  const wrapped = wrappedCurrency(currency, chainId)
  //
  const tokenPairs: [Currency | undefined, Currency | undefined][] = useMemo(
    () => [
      [chainId && wrapped && currencyEquals(WBNB, wrapped) ? undefined : currency, chainId ? WBNB : undefined],
      [wrapped?.equals(BUSD_MAINNET) ? undefined : wrapped, chainId === ChainId.MAINNET ? BUSD_MAINNET : undefined],
      [chainId ? WBNB : undefined, chainId === ChainId.MAINNET ? BUSD_MAINNET : undefined],
    ],
    [chainId, currency, wrapped],
  )
  // 通过usePairs函数获取三个交易对的状态和信息，分别是WBNB与代币、BUSD与代币、WBNB与BUSD的交易对信息。
  const [[ethPairState, ethPair], [busdPairState, busdPair], [busdEthPairState, busdEthPair]] = usePairs(tokenPairs)

  return useMemo(() => {
    
    if (!currency || !wrapped || !chainId) {
      return undefined
    }
    // handle weth/eth
    // 如果代币是WBNB（Wrapped Binance Coin），则检查是否存在WBNB与BUSD的交易对，如果存在，则计算WBNB与BUSD的价格。
    if (wrapped.equals(WBNB)) {
      if (busdPair) {
        const price = busdPair.priceOf(WBNB)
        return new Price(currency, BUSD_MAINNET, price.denominator, price.numerator)
      }
      return undefined
    }
    // handle busd
    // 如果代币是BUSD（Binance USD），则直接返回价格为1。
    if (wrapped.equals(BUSD_MAINNET)) {
      return new Price(BUSD_MAINNET, BUSD_MAINNET, '1', '1')
    }
    
    const ethPairETHAmount = ethPair?.reserveOf(WBNB)
    const ethPairETHBUSDValue: JSBI =
      ethPairETHAmount && busdEthPair ? busdEthPair.priceOf(WBNB).quote(ethPairETHAmount).raw : JSBI.BigInt(0)

    // all other tokens
    // first try the busd pair
    // 这个条件首先检查busdPairState是否等于PairState.EXISTS，表示BUSD与代币的交易对存在。
    // 接着检查busdPair是否存在，如果不存在则表示没有BUSD与代币的交易对。
    // 最后，检查BUSD与代币交易对中的BUSD储备是否大于ethPairETHBUSDValue，ethPairETHBUSDValue是在之前的代码中计算的值，表示WBNB与BUSD的价值。
    // 如果上述条件都满足，它会计算BUSD与代币的价格，然后返回代币与BUSD的价格。
    if (
      busdPairState === PairState.EXISTS &&
      busdPair &&
      busdPair.reserveOf(BUSD_MAINNET).greaterThan(ethPairETHBUSDValue)
    ) {
      const price = busdPair.priceOf(wrapped)
      return new Price(currency, BUSD_MAINNET, price.denominator, price.numerator)
    }

    // 这个条件首先检查ethPairState是否等于PairState.EXISTS，表示WBNB与代币的交易对存在。
    // 接着检查ethPair是否存在，如果不存在则表示没有WBNB与代币的交易对。
    // 同时，检查busdEthPairState是否等于PairState.EXISTS，表示BUSD与WBNB的交易对存在。
    // 最后，检查BUSD与WBNB交易对中的BUSD储备大于零，以及WBNB与代币交易对中的WBNB储备大于零。
    // 如果上述条件都满足，它会执行以下操作来计算代币与BUSD的价格：
    // 获取BUSD与WBNB的价格（ethBusdPrice）。
    // 获取WBNB与代币的价格（currencyEthPrice）。
    // 使用这两个价格相乘，然后取倒数（busdPrice = ethBusdPrice.multiply(currencyEthPrice).invert()）。
    // 最后，返回代币与BUSD的价格。
    // 这部分代码的目的是根据不同情况来选择不同的交易对来计算代币与BUSD的价格，以确保获得最准确的价格数据。根据不同的市场情况，
    // 有时会使用BUSD与代币的交易对，有时会使用WBNB与代币的交易对，以计算代币的BUSD价格。
    if (ethPairState === PairState.EXISTS && ethPair && busdEthPairState === PairState.EXISTS && busdEthPair) {
      if (busdEthPair.reserveOf(BUSD_MAINNET).greaterThan('0') && ethPair.reserveOf(WBNB).greaterThan('0')) {
        const ethBusdPrice = busdEthPair.priceOf(BUSD_MAINNET)
        const currencyEthPrice = ethPair.priceOf(WBNB)
        const busdPrice = ethBusdPrice.multiply(currencyEthPrice).invert()
        return new Price(currency, BUSD_MAINNET, busdPrice.denominator, busdPrice.numerator)
      }
    }
    //最终返回代币与BUSD的价格。
    return undefined
  }, [chainId, currency, ethPair, ethPairState, busdEthPair, busdEthPairState, busdPair, busdPairState, wrapped])

}
//这是一个导出的函数，用于获取Cake代币与BUSD的价格。它内部调用了useBUSDPrice函数，传入Cake代币，然后返回Cake代币的价格。
export const useCakeBusdPrice = (): Price | undefined => {
  const cakeBusdPrice = useBUSDPrice(tokens.cake)
  return cakeBusdPrice
}
//这是一个导出的函数，用于计算给定代币和数量的BUSD价值。它接受两参数：代币类型currency和数量amount。
//内部使用useBUSDPrice获取代币的BUSD价格，然后使用multiplyPriceByAmount函数将数量转换为BUSD价值。
export const useBUSDCurrencyAmount = (currency: Currency, amount: number): number | undefined => {
  const { chainId } = useActiveWeb3React()
  const busdPrice = useBUSDPrice(currency)
  const wrapped = wrappedCurrency(currency, chainId)
  if (busdPrice) {
    return multiplyPriceByAmount(busdPrice, amount, wrapped.decimals)
  }
  return undefined
}
// 这是一个导出的函数，用于计算给定Cake代币数量的BUSD价值。
//它内部调用useCakeBusdPrice获取Cake代币的价格，然后使用multiplyPriceByAmount函数将数量转换为BUSD价值。
export const useBUSDCakeAmount = (amount: number): number | undefined => {
  const cakeBusdPrice = useCakeBusdPrice()
  if (cakeBusdPrice) {
    return multiplyPriceByAmount(cakeBusdPrice, amount)
  }
  return undefined
}
//这是一个导出的函数，用于获取BNB（Binance Coin）与BUSD的价格。它内部调用useBUSDPrice函数，传入BNB代币，然后返回BNB代币与BUSD的价格。
export const useBNBBusdPrice = (): Price | undefined => {
  const bnbBusdPrice = useBUSDPrice(tokens.wbnb)
  return bnbBusdPrice
}
