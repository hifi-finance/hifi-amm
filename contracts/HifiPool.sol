// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "hardhat/console.sol";

import "@paulrberg/contracts/token/erc20/Erc20.sol";
import "@paulrberg/contracts/token/erc20/IErc20.sol";
import "@paulrberg/contracts/token/erc20/Erc20Permit.sol";
import "@paulrberg/contracts/token/erc20/SafeErc20.sol";

import "./Errors.sol";
import "./IHifiPool.sol";
import "./external/hifi/HTokenLike.sol";
import "./math/YieldSpace.sol";

/// @title HifiPool
/// @author Hifi
contract HifiPool is
    IHifiPool, /// no dependency
    Erc20, /// one dependency
    Erc20Permit /// four dependencies
{
    using SafeErc20 for IErc20;

    /// @inheritdoc IHifiPool
    uint256 public override maturity;

    /// @inheritdoc IHifiPool
    HTokenLike public override hToken;

    /// @inheritdoc IHifiPool
    IErc20 public override underlying;

    /// @inheritdoc IHifiPool
    uint256 public override underlyingPrecisionScalar;

    /// @dev Trading can only occur prior to maturity.
    modifier isBeforeMaturity() {
        if (block.timestamp >= maturity) {
            revert BondMatured();
        }
        _;
    }

    /// @notice Instantiates the HifiPool.
    /// @dev The HifiPool LP token always has 18 decimals.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param hToken_ The contract address of the hToken.
    /// @param underlying_ The contract address of the underlying.
    constructor(
        string memory name_,
        string memory symbol_,
        HTokenLike hToken_,
        IErc20 underlying_
    ) Erc20Permit(name_, symbol_, 18) {
        // Save the hToken contract address in storage and sanity check it.
        hToken = hToken_;

        // Calculate the precision scalar and save the underlying contract address in storage.
        uint256 underlyingDecimals = underlying_.decimals();
        if (underlyingDecimals == 0 || underlyingDecimals > 18) {
            revert HifiPoolConstructorUnderlyingDecimals(underlyingDecimals);
        }
        underlyingPrecisionScalar = 10**(18 - underlyingDecimals);
        underlying = underlying_;

        // Save the hToken maturity time in storage.
        maturity = hToken_.expirationTime();
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPool
    function getQuoteForBuyingHToken(uint256 hTokenOut)
        public
        view
        override
        isBeforeMaturity
        returns (uint256 underlyingIn)
    {
        uint256 virtualHTokenReserves = getVirtualHTokenReserves();
        uint256 normalizedUnderlyingReserves = getNormalizedUnderlyingReserves();
        uint256 normalizedUnderlyingIn;
        unchecked {
            normalizedUnderlyingIn = YieldSpace.underlyingInForHTokenOut(
                virtualHTokenReserves,
                normalizedUnderlyingReserves,
                hTokenOut,
                maturity - block.timestamp
            );
            if (virtualHTokenReserves - hTokenOut < normalizedUnderlyingReserves + normalizedUnderlyingIn) {
                revert BuyHTokenInsufficientResultantReserves(
                    virtualHTokenReserves,
                    hTokenOut,
                    normalizedUnderlyingReserves,
                    normalizedUnderlyingIn
                );
            }
        }
        underlyingIn = denormalize(normalizedUnderlyingIn);
    }

    /// @inheritdoc IHifiPool
    function getQuoteForBuyingUnderlying(uint256 underlyingOut)
        public
        view
        override
        isBeforeMaturity
        returns (uint256 hTokenIn)
    {
        unchecked {
            hTokenIn = YieldSpace.hTokenInForUnderlyingOut(
                getNormalizedUnderlyingReserves(),
                getVirtualHTokenReserves(),
                normalize(underlyingOut),
                maturity - block.timestamp
            );
        }
    }

    /// @inheritdoc IHifiPool
    function getQuoteForSellingHToken(uint256 hTokenIn)
        public
        view
        override
        isBeforeMaturity
        returns (uint256 underlyingOut)
    {
        unchecked {
            uint256 normalizedUnderlyingOut = YieldSpace.underlyingOutForHTokenIn(
                getVirtualHTokenReserves(),
                getNormalizedUnderlyingReserves(),
                hTokenIn,
                maturity - block.timestamp
            );
            underlyingOut = denormalize(normalizedUnderlyingOut);
        }
    }

    /// @inheritdoc IHifiPool
    function getQuoteForSellingUnderlying(uint256 underlyingIn)
        public
        view
        override
        isBeforeMaturity
        returns (uint256 hTokenOut)
    {
        uint256 normalizedUnderlyingReserves = getNormalizedUnderlyingReserves();
        uint256 virtualHTokenReserves = getVirtualHTokenReserves();
        uint256 normalizedUnderlyingIn = normalize(underlyingIn);
        unchecked {
            hTokenOut = YieldSpace.hTokenOutForUnderlyingIn(
                normalizedUnderlyingReserves,
                virtualHTokenReserves,
                normalizedUnderlyingIn,
                maturity - block.timestamp
            );
            if (virtualHTokenReserves - hTokenOut < normalizedUnderlyingReserves + normalizedUnderlyingIn) {
                revert SellUnderlyingInsufficientResultantReserves(
                    virtualHTokenReserves,
                    hTokenOut,
                    normalizedUnderlyingReserves,
                    normalizedUnderlyingIn
                );
            }
        }
    }

    /// @inheritdoc IHifiPool
    function getNormalizedUnderlyingReserves() public view override returns (uint256 normalizedUnderlyingReserves) {
        normalizedUnderlyingReserves = normalize(underlying.balanceOf(address(this)));
    }

    /// @inheritdoc IHifiPool
    function getVirtualHTokenReserves() public view override returns (uint256 virtualHTokenReserves) {
        unchecked {
            uint256 hTokenBalance = hToken.balanceOf(address(this));
            virtualHTokenReserves = hTokenBalance + totalSupply;
            if (virtualHTokenReserves < hTokenBalance) {
                revert VirtualHTokenReservesOverflow(hTokenBalance, totalSupply);
            }
        }
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHifiPool
    function burn(uint256 poolTokensBurned)
        external
        override
        returns (uint256 underlyingReturned, uint256 hTokenReturned)
    {
        // Checks: avoid the zero edge case.
        if (poolTokensBurned == 0) {
            revert BurnZero();
        }

        uint256 supply = totalSupply;
        uint256 normalizedUnderlyingReserves = getNormalizedUnderlyingReserves();

        // This block avoids the stack too deep error.
        {
            // Use the actual reserves rather than the virtual reserves.
            uint256 hTokenReserves = hToken.balanceOf(address(this));
            uint256 normalizedUnderlyingReturned = (poolTokensBurned * normalizedUnderlyingReserves) / supply;
            underlyingReturned = denormalize(normalizedUnderlyingReturned);
            hTokenReturned = (poolTokensBurned * hTokenReserves) / supply;
        }

        // Effects
        burnInternal(msg.sender, poolTokensBurned);

        // Interactions
        underlying.safeTransfer(msg.sender, underlyingReturned);
        if (hTokenReturned > 0) {
            hToken.transfer(msg.sender, hTokenReturned);
        }

        emit RemoveLiquidity(maturity, msg.sender, underlyingReturned, hTokenReturned, poolTokensBurned);
    }

    /// @inheritdoc IHifiPool
    function buyHToken(address to, uint256 hTokenOut) external override returns (uint256 underlyingIn) {
        // Checks: avoid the zero edge case.
        if (hTokenOut == 0) {
            revert BuyHTokenZero();
        }

        underlyingIn = getQuoteForBuyingHToken(hTokenOut);

        // Interactions
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn);
        hToken.transfer(to, hTokenOut);

        emit Trade(maturity, msg.sender, to, -toInt256(underlyingIn), toInt256(hTokenOut));
    }

    /// @inheritdoc IHifiPool
    function buyUnderlying(address to, uint256 underlyingOut) external override returns (uint256 hTokenIn) {
        // Checks: avoid the zero edge case.
        if (underlyingOut == 0) {
            revert BuyUnderlyingZero();
        }

        hTokenIn = getQuoteForBuyingUnderlying(underlyingOut);

        // Interactions
        underlying.safeTransfer(to, underlyingOut);
        hToken.transferFrom(msg.sender, address(this), hTokenIn);

        emit Trade(maturity, msg.sender, to, toInt256(underlyingOut), -toInt256(hTokenIn));
    }

    /// @inheritdoc IHifiPool
    function mint(uint256 underlyingOffered) external override returns (uint256 poolTokensMinted) {
        // Checks: avoid the zero edge case.
        if (underlyingOffered == 0) {
            revert MintZero();
        }

        // Our native precision is 18 decimals so the underlying amount needs to be normalized.
        uint256 normalizedUnderlyingOffered = normalize(underlyingOffered);

        // When there are no LP tokens in existence, only underlying needs to be provided.
        uint256 supply = totalSupply;
        if (supply == 0) {
            // Effects
            mintInternal(msg.sender, normalizedUnderlyingOffered);

            // Interactions
            underlying.safeTransferFrom(msg.sender, address(this), underlyingOffered);

            emit AddLiquidity(maturity, msg.sender, underlyingOffered, 0, normalizedUnderlyingOffered);
            return normalizedUnderlyingOffered;
        }

        // We need to use the actual reserves rather than the virtual reserves here.
        uint256 hTokenReserves = hToken.balanceOf(address(this));
        poolTokensMinted = (supply * normalizedUnderlyingOffered) / getNormalizedUnderlyingReserves();
        uint256 hTokenRequired = (hTokenReserves * poolTokensMinted) / supply;

        // Effects
        mintInternal(msg.sender, poolTokensMinted);

        // Interactions
        underlying.safeTransferFrom(msg.sender, address(this), underlyingOffered);
        if (hTokenRequired > 0) {
            hToken.transferFrom(msg.sender, address(this), hTokenRequired);
        }

        emit AddLiquidity(maturity, msg.sender, underlyingOffered, hTokenRequired, poolTokensMinted);
    }

    /// @inheritdoc IHifiPool
    function sellHToken(address to, uint256 hTokenIn) external override returns (uint256 underlyingOut) {
        // Checks: avoid the zero edge case.
        if (hTokenIn == 0) {
            revert SellHTokenZero();
        }

        underlyingOut = getQuoteForSellingHToken(hTokenIn);

        // Interactions
        underlying.safeTransfer(to, underlyingOut);
        hToken.transferFrom(msg.sender, address(this), hTokenIn);

        emit Trade(maturity, msg.sender, to, toInt256(underlyingOut), -toInt256(hTokenIn));
    }

    /// @inheritdoc IHifiPool
    function sellUnderlying(address to, uint256 underlyingIn) external override returns (uint256 hTokenOut) {
        // Checks: avoid the zero edge case.
        if (underlyingIn == 0) {
            revert SellUnderlyingZero();
        }

        hTokenOut = getQuoteForSellingUnderlying(underlyingIn);

        // Interactions
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn);
        hToken.transfer(to, hTokenOut);

        emit Trade(maturity, msg.sender, to, -toInt256(underlyingIn), toInt256(hTokenOut));
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @notice Downscales the normalized underlying amount to have its actual decimals of precision.
    /// @param normalizedUnderlyingAmount The underlying amount with 18 decimals of precision.
    /// @param underlyingAmount The underlying amount with its actual decimals of precision.
    function denormalize(uint256 normalizedUnderlyingAmount) internal view returns (uint256 underlyingAmount) {
        unchecked {
            underlyingAmount = underlyingPrecisionScalar != 1
                ? normalizedUnderlyingAmount / underlyingPrecisionScalar
                : normalizedUnderlyingAmount;
        }
    }

    /// @notice Upscales the underlying amount to normalized form, i.e. 18 decimals of precision.
    /// @param underlyingAmount The underlying amount with its actual decimals of precision.
    /// @param normalizedUnderlyingAmount The underlying amount with 18 decimals of precision.
    function normalize(uint256 underlyingAmount) internal view returns (uint256 normalizedUnderlyingAmount) {
        normalizedUnderlyingAmount = underlyingPrecisionScalar != 1
            ? underlyingAmount * underlyingPrecisionScalar
            : underlyingAmount;
    }

    /// @notice Safe cast from uint256 to int256
    function toInt256(uint256 x) internal pure returns (int256 result) {
        if (x > uint256(type(int256).max)) {
            revert ToInt256CastOverflow(x);
        }
        result = int256(x);
    }
}
