// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../libraries/Redstone-PriceAwareOwnable.sol";

contract RandomnesFacet is PriceAwareOwnable {
    uint256[] generatedNFTIndexes;

    function getPseudoRandomness() internal view returns (uint256) {
        uint256 randomValue = getPriceFromMsg(bytes32("ENTROPY"));

        return uint256(
            keccak256(
                abi.encodePacked(randomValue, block.timestamp, blockhash(block.number - 1), blockhash(block.number))
            )
        );
    }

    // Generates a random number from 1 to maxValue
    function generateRandomNumber(uint256 maxValue) internal view returns (uint256) {
        uint256 randomness = getPseudoRandomness();
        return (randomness % maxValue) + 1;
    }

    // Firstly it generates a single random number (e.g. number of NFTs in a box)
    // Then it generates the specified number of random numbers
    function generateManyRandomNumbers(uint256 maxRandomNumbersCount, uint256 maxValue) internal {
        // randomValue = getPriceFromMsg(bytes32("RANDOM"));
        uint256 randomness = getPseudoRandomness();
        uint256 randomNumbersCount = generateRandomNumber(maxRandomNumbersCount);
        generatedNFTIndexes = new uint256[](randomNumbersCount);
        for (uint256 i = 0; i < randomNumbersCount; i++) {
            generatedNFTIndexes[i] = uint256(keccak256(abi.encode(randomness, i))) % maxValue + 1;
        }
    }

    function getGeneratedNFTIndexes() internal view returns (uint256[] memory) {
        return generatedNFTIndexes;
    }
}
