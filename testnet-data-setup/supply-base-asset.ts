import { SuiTxBlock } from '@scallop-io/sui-kit';
import { testCoinTxBuilder, testCoinTypes } from '../contracts/test_coin';
import { protocolTxBuilder } from '../contracts/protocol'

export const supplyBaseAsset = (tx: SuiTxBlock) => {

  let usdcCoin = testCoinTxBuilder.mint(tx, 10 ** 14, 'usdc');
  let usdtCoin = testCoinTxBuilder.mint(tx, 10 ** 15, 'usdt');

  protocolTxBuilder.supplyBaseAsset(tx, usdcCoin, testCoinTypes.usdc);
  protocolTxBuilder.supplyBaseAsset(tx, usdtCoin, testCoinTypes.usdt);
  return tx;
}
