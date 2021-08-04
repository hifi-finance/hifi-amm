// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/access/Ownable.sol";

import "./HifiPool.sol";
import "./IHifiPoolRegistry.sol";

/// @notice Emitted when attempting to untrack a pool and there are no tracked pools.
error HifiPoolRegistry__NoTrackedPools();

/// @notice Emitted when the pool to be tracked is already tracked.
error HifiPoolRegistry__PoolAlreadyTracked(IHifiPool pool);

/// @notice Emitted when the pool to be untracked is not tracked.
error HifiPoolRegistry__PoolNotTracked(IHifiPool pool);

/// @title HifiPoolRegistry
/// @author Hifi
contract HifiPoolRegistry is
    Ownable, // one dependency
    IHifiPoolRegistry // one dependency
{
    /// CONSTRUCTOR ///

    constructor() Ownable() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPoolRegistry
    IHifiPool[] public override pools;

    /// @inheritdoc IHifiPoolRegistry
    mapping(IHifiPool => uint256) public override poolIds;

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPoolRegistry
    function trackPool(IHifiPool pool) public override onlyOwner {
        uint256 poolId = poolIds[pool];
        if (pools.length != 0 && address(pools[poolId]) == address(pool)) {
            revert HifiPoolRegistry__PoolAlreadyTracked(pool);
        }

        pools.push(pool);
        poolIds[pool] = pools.length - 1;
        emit TrackPool(pool);
    }

    /// @inheritdoc IHifiPoolRegistry
    function untrackPool(IHifiPool pool) public override onlyOwner {
        uint256 poolId = poolIds[pool];
        if (pools.length == 0) {
            revert HifiPoolRegistry__NoTrackedPools();
        } else if (pools.length != 0 && address(pools[poolId]) != address(pool)) {
            revert HifiPoolRegistry__PoolNotTracked(pool);
        }

        pools[poolId] = pools[pools.length - 1];
        poolIds[pools[poolId]] = poolId;
        poolIds[pool] = 0;
        pools.pop();
        emit UntrackPool(pool);
    }
}
