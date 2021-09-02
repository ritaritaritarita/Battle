// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Arrays {
    //Shuffles an array of uints with random seed
    function shuffle(uint256[] memory _elements, uint256 _seed) internal pure returns (uint256[] memory) {
        for (uint256 i = 0; i < _elements.length; i++) {
            //Pick random index to swap current element with
            uint256 n = i + _seed % (_elements.length - i);

            //swap elements
            uint256 temp = _elements[n];
            _elements[n] = _elements[i];
            _elements[i] = temp;

            //Create new pseudorandom number using seed.
            _seed = uint(keccak256(abi.encodePacked(_seed)));
        }
        return _elements;
    }
}
