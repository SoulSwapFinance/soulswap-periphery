pragma solidity >=0.6.6;

import '../interfaces/IFactory.sol';

library BoringPair {
    function factory(IPair pair) internal view returns (IFactory) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSelector(0xc45a0155));
        return success && data.length == 32 ? abi.decode(data, (IFactory)) : IFactory(0);
    }
}