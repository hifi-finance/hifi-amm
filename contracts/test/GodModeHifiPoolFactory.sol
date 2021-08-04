// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "../HifiPoolFactory.sol";

/// @title GodModeHifiPoolFactory
/// @author Hifi
/// @dev Strictly for test purposes. Do not use in production.
contract GodModeHifiPoolFactory is HifiPoolFactory {
    function __godMode_setPools(IHifiPool[] calldata pools_) external {
        pools = pools_;
        for (uint256 i; i < pools_.length; i++) {
            poolIds[pools[i]] = i;
        }
    }

    function __godMode_resetPools() external {
        for (uint256 i; i < pools.length; i++) {
            poolIds[pools[i]] = 0;
        }
        delete pools;
    }
}
