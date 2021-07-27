// SPDX-License-Identifier: MIT

import './IMigrator.sol';

pragma solidity >=0.6.6;

interface ISummoner {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external; 
    function setMigrator(IMigrator _migrator) external;

    function pendingSoul(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function bonusMultiplier() external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startTime() external view returns (uint256);

    function soul() external view returns (address);
    function soulPerSecond() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (
            address,
            uint256,
            uint256,
            uint256
        );

}
