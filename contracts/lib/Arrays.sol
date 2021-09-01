// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Arrays {
    function shuffle(uint256[] memory _elements, uint256 _seed) internal pure returns (uint256[] memory) {
        for (uint256 i = 0; i < _elements.length; i++) {
            uint256 n = i + _seed % (_elements.length - i);
            uint256 temp = _elements[n];
            _elements[n] = _elements[i];
            _elements[i] = temp;
            _seed = uint(keccak256(abi.encodePacked(_seed)));
        }
        return _elements;
    }
}
