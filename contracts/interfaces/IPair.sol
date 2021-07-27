// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import '@soulswap/swap-core/contracts/interfaces/IERC20.sol';

interface IPair {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}
