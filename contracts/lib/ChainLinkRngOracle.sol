// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract ChainLinkRngOracle is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    address maticLink = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address maticVrfCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 maticKeyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;

    address mumbaiLink = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address mumbaiVrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 mumbaiKeyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;

    mapping(bytes32 => uint256) internal results;

    constructor() VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB) {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 1 ether / 1000;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
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
