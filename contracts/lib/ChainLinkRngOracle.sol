// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract ChainLinkRngOracle is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => uint256) internal results;

    constructor(address coordinator, address linkToken) VRFConsumerBase(coordinator, linkToken) {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 1 ether / 10;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(VRFConsumerBase.LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

        return VRFConsumerBase.requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        results[requestId] = randomness;
    }

    function fetchNumberByRequestId(bytes32 _requestId) public view returns (uint256) {
        return results[_requestId];
    }
}
