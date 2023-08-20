// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

// stat {
//     0: strength;
//     1: health;
//     2: agility;
//     3: magic;
//     4: defense;
//     5: luck;
// }

library StorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");

    using PlayerSlotLib for PlayerSlotLib.Player;
    using PlayerSlotLib for PlayerSlotLib.Slot;

    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => PlayerSlotLib.Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
        mapping(uint256 => PlayerSlotLib.Slot) slots;
    }


    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _getPlayer(uint256 _id) internal view returns (PlayerSlotLib.Player memory player) {
        PlayerStorage storage s = diamondStorage();
        player = s.players[_id];
    }

    function _playerCount() internal view returns (uint256) {
        PlayerStorage storage s = diamondStorage();
        return s.playerCount;
    }

}

contract ScriptFacet {

    event LevelUpPatch(uint256 indexed id, PlayerSlotLib.Player _player);

    function levelUpScript() public {
        uint256 count = StorageLib._playerCount();
        for (uint256 i = 1; i < count; i++) {
            if (StorageLib._getPlayer(i).level > 1) {
                emit LevelUpPatch(i, StorageLib._getPlayer(i));
            }
        }
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
