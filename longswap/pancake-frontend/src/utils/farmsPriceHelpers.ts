import { SerializedFarm } from 'state/types'

/**
 * Returns the first farm with a quote token that matches from an array of preferred quote tokens
 * @param farms Array of farms
 * @param preferredQuoteTokens Array of preferred quote tokens
 * @returns A preferred farm, if found - or the first element of the farms array
 */
//接受一个SerializedFarm对象数组和一个可选的优先引用令牌数组。
export const filterFarmsByQuoteToken = (
  farms: SerializedFarm[],
  preferredQuoteTokens: string[] = ['BUSD', 'WBNB'],
): SerializedFarm => {
  //函数返回第一个具有与任何优选引用令牌匹配的引用令牌的农场对象。
  //函数使用find()方法遍历农场数组并查找具有与任何优选引用令牌匹配的引用令牌的第一个农场。
  //它使用some()方法遍历优选引用令牌数组，并在农场的引用令牌符号与任何优选引用令牌匹配时返回true。
  const preferredFarm = farms.find((farm) => {
    return preferredQuoteTokens.some((quoteToken) => {
      return farm.quoteToken.symbol === quoteToken
    })
  })
  // 函数返回第一个具有与任何优选引用令牌匹配的引用令牌的农场对象。或第一个farm农场
  return preferredFarm || farms[0]
}

export default filterFarmsByQuoteToken
