// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author RedVeil
/// @title  ERC4626 Wrapper
/// @notice Wraps an external contract into a standardized ERC4626 interface for easier use.
contract Wrapper is IERC20 {
    constructor(
        IERC20 asset,
        address externalContract,
        bytes callData
    ) {}
}
