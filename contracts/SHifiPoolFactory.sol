// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IHifiPool.sol";

/// @title SHifiPoolFactory
/// @author Hifi
abstract contract SHifiPoolFactory {
    /// PUBLIC STORAGE ///

    /// @notice Array of all created AMM pools.
    IHifiPool[] public pools;

    /// @notice Maps AMM pools to their index in the array of pools.
    mapping(IHifiPool => uint256) public poolIds;
}
