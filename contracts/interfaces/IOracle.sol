pragma solidity >=0.6.6;

interface IOracle {
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}