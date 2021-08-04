// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/access/Ownable.sol";

import "./HifiPool.sol";
import "./IHifiPoolFactory.sol";

/// @notice Emitted when attempting to untrack a pool and there are no tracked pools.
error HifiPoolFactory__NoTrackedPools();

/// @notice Emitted when the pool to be tracked is already tracked.
error HifiPoolFactory__PoolAlreadyTracked(IHifiPool pool);

/// @notice Emitted when the pool to be untracked is not tracked.
error HifiPoolFactory__PoolNotTracked(IHifiPool pool);

/// @title HifiPoolFactory
/// @author Hifi
contract HifiPoolFactory is
    Ownable, // one dependency
    IHifiPoolFactory // one dependency
{
    /// CONSTRUCTOR ///

    constructor() Ownable() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPoolFactory
    IHifiPool[] public override pools;

    /// @inheritdoc IHifiPoolFactory
    mapping(IHifiPool => uint256) public override poolIds;

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPoolFactory
    function createPool(
        string memory name,
        string memory symbol,
        IHToken hToken
    ) public override onlyOwner returns (IHifiPool pool) {
        pool = new HifiPool(name, symbol, hToken);
        emit CreatePool(pool);
        trackPool(pool);
    }

    /// @inheritdoc IHifiPoolFactory
    function trackPool(IHifiPool pool) public override onlyOwner {
        uint256 poolId = poolIds[pool];
        if (pools.length != 0 && address(pools[poolId]) == address(pool)) {
            revert HifiPoolFactory__PoolAlreadyTracked(pool);
        }

        pools.push(pool);
        poolIds[pool] = pools.length - 1;
        emit TrackPool(pool);
    }

    /// @inheritdoc IHifiPoolFactory
    function untrackPool(IHifiPool pool) public override onlyOwner {
        uint256 poolId = poolIds[pool];
        if (pools.length == 0) {
            revert HifiPoolFactory__NoTrackedPools();
        } else if (pools.length != 0 && address(pools[poolId]) != address(pool)) {
            revert HifiPoolFactory__PoolNotTracked(pool);
        }

        pools[poolId] = pools[pools.length - 1];
        poolIds[pools[poolId]] = poolId;
        poolIds[pool] = 0;
        pools.pop();
        emit UntrackPool(pool);
    }
}
