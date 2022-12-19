pragma solidity ^0.6.0;

import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/IUniswapV3Pair.sol";
import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/IUniswapV3Router01.sol";
import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/UniswapV3Factory.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";

contract FlashSwapArbitrage {
    using SafeMath for uint256;

    IUniswapV3Router01 router;
    address factoryAddress;
    address[] pairAddresses;

    constructor(IUniswapV3Router01 _router, address _factoryAddress) public {
        router = _router;
        factoryAddress = _factoryAddress;
    }

    function setPairAddresses(address[] memory _pairAddresses) public {
        pairAddresses = _pairAddresses;
    }

    function executeArbitrage(uint256 _amountIn, uint256 _minReturn) public {
        for (uint256 i = 0; i < pairAddresses.length; i++) {
            IUniswapV3Pair pair = IUniswapV3Pair(pairAddresses[i]);
            // get the exchange rate for buying the first token with the second token
            uint256 buyRate = pair.getBuyPrice(_amountIn);
            // get the exchange rate for selling the first token for the second token
            uint256 sellRate = pair.getSellPrice(_amountIn);

            // if the difference between the buy and sell rates is greater than the minimum return, execute the trade
            if (sellRate.sub(buyRate).gt(_minReturn)) {
                // calculate the amount of the second token that will be received in the trade
                uint256 amountOut = _amountIn.mul(sellRate).div(buyRate);
                // execute the trade
                router.swapExactTokensForTokens(
                    _amountIn,
                    1,
                    pair.token0(),
                    pair.token1(),
                    amountOut,
                    1,
                    pair.token1(),
                    pair.token0(),
                    msg.sender
                );
            }
        }
    }
}
