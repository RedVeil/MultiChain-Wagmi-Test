// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @author RedVeil
/// @title  AbstractBytesDecoder
/// @notice Decode functions and input params dynamically.
abstract contract AbstractBytesDecoder {
    struct InputParam {
        uint128 typeId;
        bytes param;
    }

    // 4/5 array of [uint4,bytes] for input params
    // First uint4 for type decoding
    // Second bytes data that needs to be decoded
    // 0 - Empty
    // 1 - int
    // 2 - uint
    // 3 - int128
    // 4 - uint128
    // 5 - int256
    // 6 - uint256
    // 7 - address
    // 8 - bytes
    // 9 - bytes32
    // 10 - string
    // 11 - balanceOf(address(this))
    // 12 - pass in user balance
    // 13 - ...

    function decodeParam(InputParam memory param) internal {
        if (param.typeId == 0) {} else if (param.typeId == 1) {} else {}
    }
}
