// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PlayerSlotLib.sol";


struct TreasureSchema {
    uint256 treasureSchemaId;
    uint256 rank;
    string name;
    string uri;
}

struct Treasure {
    uint256 id;
    uint256 treasureSchemaId;
    uint256 owner;
    uint256 rank;
    uint256 pointer;
    string name;
    string uri;
}


library TreasureStorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant TREASURE_STORAGE_POSITION = keccak256("treasure.test.storage.a");

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
    }

    struct TreasureStorage {
        uint256 treasureCount;
        uint256 treasureScehmaCount;
        mapping(uint256 => TreasureSchema) treasureSchema;
        mapping(uint256 => address) owners;
        mapping(uint256 => Treasure) treasures;
        mapping(uint256 => uint256[]) playerToTreasure;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTreasure() internal pure returns (TreasureStorage storage ds) {
        bytes32 position = TREASURE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _createTreasureScehma(
        uint256 _rank,
        string memory _name,
        string memory _uri
    ) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        tr.treasureScehmaCount++; //increment basicTreasureCount
        tr.treasureSchema[tr.treasureScehmaCount] = TreasureSchema(
            tr.treasureScehmaCount, _rank, _name, _uri
        );
    }

    function _mintTreasure(uint256 _playerId, uint256 _treasureSchemaId) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        tr.treasureCount++;
        TreasureSchema memory treasureSchema = tr.treasureSchema[_treasureSchemaId];
        tr.treasures[tr.treasureCount] = Treasure(
            tr.treasureCount,
            _treasureSchemaId,
            _playerId,
            treasureSchema.rank,
            tr.playerToTreasure[_playerId].length,
            treasureSchema.name,
            treasureSchema.uri
        );
        tr.playerToTreasure[_playerId].push(tr.treasureCount);
    }

    function _deleteTreasure(uint256 _playerId, uint256 _treasureId) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        require(tr.treasures[_treasureId].owner == _playerId);
        uint256 rowToDelete = tr.treasures[_treasureId].pointer;
        uint256 keyToMove = tr.playerToTreasure[_playerId].length -1;
        tr.playerToTreasure[_playerId][rowToDelete] = keyToMove;
        tr.treasures[keyToMove].pointer = rowToDelete;
        tr.playerToTreasure[_playerId].pop();
    }

}