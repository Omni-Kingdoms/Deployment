// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";


struct TreasureSchema {
    uint256 basicTreasureId;
    uint256 rank;
    string name;
    string uri;
}

struct Treasure {
    uint256 id;
    uint256 treasureId;
    uint256 owner;
    uint256 rank;
    uint256 pointer;
    string name;
    string uri;
}

library StorageLib {
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

    function _createTreasureSchema(
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

    function _getTreasureSchemaCounter() internal view returns (uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return (tr.treasureScehmaCount);
    }

    function _getTreasure(uint256 _treasureId) internal view returns (Treasure memory) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasures[_treasureId];
    }

    function _getTreasureSchema(uint256 _treasureSchemaId) internal view returns (TreasureSchema memory) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasureSchema[_treasureSchemaId];
    }

}

contract TreasureFacet {
    event TreasureSchemaCreation(uint256 indexed _treasureSchemaId);

    function createTreasureSchema(uint256 _rank, string memory _name, string memory _uri) public {
        StorageLib._createTreasureSchema(_rank, _name, _uri);
        emit TreasureSchemaCreation(StorageLib._getTreasureSchemaCounter());
    }

    function getTreasureSchemaCounter() public view returns (uint256) {
        return (StorageLib._getTreasureSchemaCounter());
    }

    function getTreasure(uint256 _treasureId) public view returns (Treasure memory) {
        return (StorageLib._getTreasure(_treasureId));

    }

    function getTreasureSchema(uint256 _treasureSchemaId) public view returns (TreasureSchema memory) {
        return (StorageLib._getTreasureSchema(_treasureSchemaId));
    }
    
    
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}