// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IToken } from "./IToken.sol";

interface IReflectionToken is IToken {
    event LiquidityAdded(uint256 amountToken, uint256 amountEth);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    function deliver(uint256 tokenAmount) external;
    function excludeFromFee(address account) external;
    function excludeFromReward(address account) external;
    function feeRecipient() external view returns (address);
    function includeInFee(address account) external;
    function includeInReward(address account) external;
    function isExcludedFromFee(address account) external view returns (bool);
    function isExcludedFromReward(address account) external view returns (bool);
    function liquidityFeePercent() external view returns (uint256);
    function lpToken() external view returns (address);
    function maxAccumulatedTaxThreshold() external view returns (uint256);
    function maxTxAmount() external view returns (uint256);
    function platformFeePercent() external view returns (uint256);
    function platformFeeRecipient() external view returns (address);
    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) external view returns (uint256);
    function setLiquidityFeePercent(uint256 liquidityFeePercent_) external;
    function setMaxTxPercent(uint256 maxTxPercent) external;
    function setSwapAndLiquifyEnabled(bool _enabled) external;
    function setTaxFeePercent(uint256 taxFee) external;
    function taxPercent() external view returns (uint256);
    function tokenFromReflection(uint256 reflectionAmount) external view returns (uint256);
    function totalFees() external view returns (uint256);
}
