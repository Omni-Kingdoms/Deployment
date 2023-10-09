// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TreasureSchema {
    uint256 basicTreasureId;
    uint256 rank;
    string name;
    string uri;
}

library TreasureStorageLib {
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant TREASURE_STORAGE_POSITION = keccak256("treasure.test.storage.a");


    struct TreasureStorage {
        uint256 treasureScehmaCount;
        mapping(uint256 => TreasureSchema) treasureSchema;
        mapping(uint256 => mapping(uint256 => uint256)) treasures;
        mapping(string => TreasureSchema) nameToTreasureSchema;
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
        tr.nameToTreasureSchema[_name] = TreasureSchema(
            tr.treasureScehmaCount, _rank, _name, _uri
        );
    }

    function _mintTreasure(uint256 _playerId, uint256 _treasureSchemaId) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        tr.treasures[_treasureSchemaId][_playerId]++;

    }

    function _deleteTreasure(uint256 _playerId, uint256 _treasureScehmaId) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        require(tr.treasures[_treasureScehmaId][_playerId] >= 1);
        tr.treasures[_treasureScehmaId][_playerId] -= 1;

    }

    function _getTreasureSchemaCounter() internal view returns (uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return (tr.treasureScehmaCount);
    }

    function _getTreasurePlayer(uint256 _playerId, uint256 _treasureSchemaId) internal view returns (uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasures[_treasureSchemaId][_playerId];
    }

    function _getTreasureSchema(uint256 _treasureSchemaId) internal view returns (TreasureSchema memory) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasureSchema[_treasureSchemaId];
    }


}

contract TreasureFacet {
    event TreasureSchemaCreation(TreasureSchema _treasureSchemaId);
    event MintTreasure(uint256 _playerId, TreasureSchema _treasureSchemaId);

    function createTreasureSchema(uint256 _rank, string memory _name, string memory _uri) public {
        TreasureStorageLib._createTreasureSchema(_rank, _name, _uri);
        emit TreasureSchemaCreation(getTreasureSchema(getTreasureSchemaCounter()));
    }

    function mintTreasure(uint256 _playerId, uint256 _treasureSchemaId) public {
        TreasureStorageLib._mintTreasure(_playerId, _treasureSchemaId);
        emit MintTreasure(_playerId, getTreasureSchema(_treasureSchemaId));
    }

    function getTreasureSchemaCounter() public view returns (uint256) {
        return (TreasureStorageLib._getTreasureSchemaCounter());
    }

    function getTreasurePlayer(uint256 _playerId, uint256 _treasureId) public view returns (uint256) {
        return (TreasureStorageLib._getTreasurePlayer(_playerId, _treasureId));
    }

    function getTreasureSchema(uint256 _treasureSchemaId) public view returns (TreasureSchema memory) {
        return (TreasureStorageLib._getTreasureSchema(_treasureSchemaId));
    }

    
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}