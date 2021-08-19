// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ChainLinkRngOracle.sol";

// todo allow chain link oracle to be changed
contract RandomNumberGenerator is Ownable {
    event FetchingRandomNumber(uint256 _id, bytes32 _requestId, uint256 _when);

    address internal chainLinkOracle;

    mapping(uint256 => bytes32) internal requestNumberToRequestId;
    uint256 internal counter;

    constructor(address _chainLinkOracle) {
        chainLinkOracle = _chainLinkOracle;
        counter = 1;
    }

    function requestRandomNumber() public onlyOwner returns (bytes32) {
        bytes32 requestId = ChainLinkRngOracle(chainLinkOracle).getRandomNumber();

        requestNumberToRequestId[counter] = requestId;
        emit FetchingRandomNumber(counter, requestId, block.timestamp);
        counter = counter + 1;

        return requestId;
    }

    function fetchRandomNumber(uint256 _maximum, bytes32 _requestId) public view returns (uint256) {
        uint256 randomNumber = ChainLinkRngOracle(chainLinkOracle).fetchNumberByRequestId(_requestId);

        return (randomNumber % _maximum) + 1;
    }
}
