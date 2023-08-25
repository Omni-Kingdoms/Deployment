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
        mapping(uint256 => mapping(uint256 => uint256)) treasures;
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
        //TreasureSchema memory treasureSchema = tr.treasureSchema[_treasureSchemaId];
        tr.treasures[_treasureSchemaId][_playerId]++;
        // tr.treasures[tr.treasureCount] = Treasure(
        //     tr.treasureCount,
        //     _treasureSchemaId,
        //     _playerId,
        //     treasureSchema.rank,
        //     tr.playerToTreasure[_playerId].length,
        //     treasureSchema.name,
        //     treasureSchema.uri
        // );
        //tr.playerToTreasure[_playerId].push(tr.treasureCount);
    }

    function _deleteTreasure(uint256 _playerId, uint256 _treasureScehmaId) internal {
        TreasureStorage storage tr = diamondStorageTreasure();
        require(tr.treasures[_treasureScehmaId][_playerId] >= 1);
        tr.treasures[_treasureScehmaId][_playerId] -= 1;
        // uint256 rowToDelete = tr.treasures[_treasureId].pointer;
        // uint256 keyToMove = tr.playerToTreasure[_playerId].length -1;
        // tr.playerToTreasure[_playerId][rowToDelete] = keyToMove;
        // tr.treasures[keyToMove].pointer = rowToDelete;
        // tr.playerToTreasure[_playerId].pop();
    }

    function _getTreasureSchemaCounter() internal view returns (uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return (tr.treasureScehmaCount);
    }

    function _getTreasureCount() internal view returns(uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return (tr.treasureCount);
    }

    function _getTreasurePlayer(uint256 _playerId, uint256 _treasureSchemaId) internal view returns (uint256) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasures[_treasureSchemaId][_playerId];
    }

    function _getTreasureSchema(uint256 _treasureSchemaId) internal view returns (TreasureSchema memory) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.treasureSchema[_treasureSchemaId];
    }

    function _getTreasures(uint256 _playerId) internal view returns (uint256[] memory) {
        TreasureStorage storage tr = diamondStorageTreasure();
        return tr.playerToTreasure[_playerId];
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

    function getTreasureCount() public view returns (uint256) {
        return TreasureStorageLib._getTreasureCount();
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

    function getTreasures(uint256 _playerId) external view returns (uint256[] memory) {
        return TreasureStorageLib._getTreasures(_playerId);
    }
    
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}