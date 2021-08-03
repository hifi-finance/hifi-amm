// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IHifiPool.sol";

/// @title IHifiPoolFactory
/// @author Hifi
interface IHifiPoolFactory {
    /// EVENTS ///

    event CreatePool(IHifiPool indexed pool);

    event TrackPool(IHifiPool indexed pool);

    event UntrackPool(IHifiPool indexed pool);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new AMM pool.
    ///
    /// @dev Emits a {CreatePool} and a {TrackPool} event.
    ///
    /// @param name Erc20 name of the pool token.
    /// @param symbol Erc20 symbol of the pool token.
    /// @param hToken The contract address of the hToken.
    /// @return pool The reference to the created pool.
    function createPool(
        string memory name,
        string memory symbol,
        IHToken hToken
    ) external returns (IHifiPool pool);

    /// @notice Tracks a new AMM pool.
    ///
    /// @dev Emits a {TrackPool} event.
    ///
    /// Requirements:
    /// - The pool shouldn't have already been tracked by factory.
    ///
    /// @param pool The reference to the pool to be tracked.
    function trackPool(IHifiPool pool) external;

    /// @notice Utracks a previously-tracked AMM pool.
    ///
    /// @dev Emits an {UntrackPool} event.
    ///
    /// Requirements:
    /// - The pool should have already been tracked by factory.
    ///
    /// @param pool The reference to the pool to be untracked.
    function untrackPool(IHifiPool pool) external;
}
