// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {ERC4626, SafeTransferLib, FixedPointMathLib} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @author RedVeil
/// @title  ERC4626 Wrapper
/// @notice Wraps an external contract into a standardized ERC4626 interface for easier use.
contract Wrapper is ERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    struct CallConfig {
        bytes4 signature;
        bool hasDynamicInput;
        bool transformInput;
        uint8 dynamicInputIndex;
        bytes[] additionalParams;
        uint8 additionalParamsLength;
    }

    address public target;

    CallConfig internal depositCall;
    CallConfig internal withdrawalCall;
    CallConfig internal claimCall;
    CallConfig internal totalAssetsCall;
    bytes internal pricePerShareCall;

    uint256 public targetDepositFee; // in 1e18
    uint256 public targetWithdrawalFee; // in 1e18

    //TODO How to deal with claiming / non-claiming wrapper?
    //TODO Find method to give each wrapped vault a unique name and symbol
    constructor(
        ERC20 _asset,
        address _target,
        CallConfig memory _depositCall,
        CallConfig memory _withdrawalCall,
        CallConfig memory _claimCall,
        CallConfig memory _totalAssetsCall,
        bytes memory _pricePerShareCall,
        uint256 _targetDepositFee,
        uint256 _targetWithdrawalFee
    )
        ERC4626(
            _asset,
            string(abi.encodePacked("Wrapped ", _asset.name(), " Vault")),
            string(abi.encodePacked("wv", _asset.symbol()))
        )
    {
        target = _target;

        depositCall = _depositCall;
        withdrawalCall = _withdrawalCall;
        claimCall = _claimCall;
        totalAssetsCall = _totalAssetsCall;
        pricePerShareCall = _pricePerShareCall;

        targetDepositFee = _targetDepositFee;
        targetWithdrawalFee = _targetWithdrawalFee;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    error totalAssetsReverted();

    function totalAssets() public view override returns (uint256) {
        (bool success, bytes memory result) = target.staticcall(
            prepareCall(totalAssetsCall, ERC20(target).balanceOf(address(this)))
        );
        if (success) return abi.decode(result, (uint256));
        revert totalAssetsReverted();
    }

    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        if (targetDepositFee != uint256(0))
            assets = assets.mulDivUp(1e18 - targetDepositFee, 1e18);
        return convertToShares(assets);
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        uint256 assets = supply == 0
            ? shares
            : shares.mulDivUp(totalAssets(), supply);

        if (targetDepositFee != uint256(0))
            assets = assets.mulDivUp(1e18 - targetDepositFee, 1e18);
        return assets;
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        uint256 shares = supply == 0
            ? assets
            : assets.mulDivUp(supply, totalAssets());

        if (targetDepositFee != uint256(0))
            shares = shares.mulDivUp(1e18, (1e18 - targetWithdrawalFee));
        return shares;
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        if (targetDepositFee != uint256(0))
            shares = shares.mulDivUp(1e18, (1e18 - targetWithdrawalFee));

        return convertToAssets(shares);
    }

    function convertToWrappedAsset(uint256 assets)
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory result) = target.staticcall(
            pricePerShareCall
        );
        if (success)
            return assets.mulDivUp(1e18, abi.decode(result, (uint256)));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    error withdrawalFailed(string);

    function beforeWithdraw(uint256 assets, uint256) internal override {
        (bool success, bytes memory result) = target.call(
            prepareCall(withdrawalCall, assets)
        );
        if (!success) revert withdrawalFailed(decodeErrorMessage(result));
    }

    error depositFailed(string);

    function afterDeposit(uint256 assets, uint256) internal override {
        (bool success, bytes memory result) = target.call(
            prepareCall(depositCall, assets)
        );
        if (!success) revert depositFailed(decodeErrorMessage(result));
    }

    function prepareCall(CallConfig memory callConfig, uint256 assets)
        internal
        view
        returns (bytes memory)
    {
        bytes memory callData;
        if (callConfig.hasDynamicInput) {
            bytes memory encodedAmount = abi.encode(
                callConfig.transformInput
                    ? convertToWrappedAsset(assets)
                    : assets
            );
            if (callConfig.additionalParamsLength == 0) {
                callData = encodedAmount;
            } else {
                callData = addAdditionalParamsToAssets(
                    callConfig,
                    encodedAmount
                );
            }
        } else if (
            !callConfig.hasDynamicInput &&
            callConfig.additionalParamsLength == 0
        ) {
            callData = "";
        }
        return abi.encodePacked(callConfig.signature, callData);
    }

    function addAdditionalParamsToAssets(
        CallConfig memory callConfig,
        bytes memory amount
    ) internal pure returns (bytes memory) {
        bytes[] memory params = callConfig.additionalParams;
        params[callConfig.dynamicInputIndex] = amount;
        return encodeParams(params);
    }

    function encodeParams(bytes[] memory params)
        internal
        pure
        returns (bytes memory callData)
    {
        callData = params[0];
        for (uint8 i = 1; i < params.length; i++) {
            callData = bytes.concat(callData, params[i]);
        }
    }

    function decodeErrorMessage(bytes memory result)
        internal
        pure
        returns (string memory errorMessage)
    {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) return "";
        assembly {
            result := add(result, 0x04)
        }
        return abi.decode(result, (string));
    }
}
