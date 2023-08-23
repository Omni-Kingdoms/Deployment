// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TreasureSchema {
    uint256 basicTreasureId;
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
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant TREASURE_STORAGE_POSITION = keccak256("treasure.test.storage.a");


    struct TreasureStorage {
        uint256 treasureCount;
        uint256 treasureScehmaCount;
        mapping(uint256 => TreasureSchema) treasureSchema;
        //mapping(uint256 => address) owners;
        mapping(uint256 => Treasure) treasures;
        mapping(uint256 => uint256[]) playerToTreasure;
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
    event MintTreasure(TreasureSchema _treasureSchemaId);

    function createTreasureSchema(uint256 _rank, string memory _name, string memory _uri) public {
        TreasureStorageLib._createTreasureSchema(_rank, _name, _uri);
        emit TreasureSchemaCreation(TreasureStorageLib._getTreasureSchemaCounter());
    }

    function getTreasureSchemaCounter() public view returns (uint256) {
        return (TreasureStorageLib._getTreasureSchemaCounter());
    }

    function getTreasure(uint256 _treasureId) public view returns (Treasure memory) {
        return (TreasureStorageLib._getTreasure(_treasureId));
    }

    function getTreasureSchema(uint256 _treasureSchemaId) public view returns (TreasureSchema memory) {
        return (TreasureStorageLib._getTreasureSchema(_treasureSchemaId));
    }
    
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}