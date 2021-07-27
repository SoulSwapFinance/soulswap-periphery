// SPDX-License-Identifier: MIT

import '@soulswap/swap-core/contracts/interfaces/IERC20.sol';

pragma solidity >=0.6.6;

interface IMigrator {
    // Perform LP token migration from legacy.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.

    function migrate(IERC20 token) external returns (IERC20);
}
