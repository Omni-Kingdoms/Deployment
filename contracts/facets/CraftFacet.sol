// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import "../libraries/TreasureLib.sol";

struct BasicEquipmentSchema {
    uint256 basicEquipmentSchemaId;
    uint256 slot;
    uint256 value;
    uint256 stat;
    uint256 cost;
    uint256 supply;
    string name;
    string uri;
}

struct Equipment {
    uint256 id;
    uint256 pointer;
    uint256 slot;
    uint256 rank;
    uint256 value;
    uint256 stat;
    uint256 owner;
    string name;
    string uri;
    bool isEquiped;
}

struct BasicCraft {
    uint256 id;
    uint256 slot;
    uint256 value;
    uint256 cost;
    string oldName;
    string newName;
    string uri;
}

struct ManaCraft {
    uint256 manaCraftId;
    uint256 slot;
    uint256 cost;
    string oldName;
    string newName;
    string uri;
}

struct AdvancedCraft {
    uint256 advancedCraftId;
    uint256 slot;
    uint256 value;
    uint256 stat;
    uint256 amount;
    uint256 treasureSchemaId;
    string oldName;
    string newName;
    string uri;
}

// stat {
//     0: strength;
//     1: health;
//     2: agility;
//     3: magic;
//     4: defense;
//     5: maxMana;
//     6: luck;
// }


library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant EQUIPMENT_STORAGE_POSITION = keccak256("equipment.test.storage.a");
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
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

    struct EquipmentStorage {
        uint256 equipmentCount;
        uint256 basicEquipmentCount;
        mapping(uint256 => BasicEquipmentSchema) basicEquipmentSchema;
        mapping(uint256 => uint256) basicEquipmentSupply;
        mapping(uint256 => Equipment) equipment;
        uint256 basicCraftCount;
        mapping(uint256 => BasicCraft) basicCraft;
        mapping(uint256 => uint256[]) playerToEquipment;
        uint256 advancedCraftCount;
        mapping(uint256 => AdvancedCraft) advancedCraft;
    }

    struct PotionStorage {
        mapping(uint256 => address) timePotion;
        mapping(address => uint256) healthPotion;
    }

    struct CoinStorage {
        uint256 goldCount;
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct TreasureStorage {
        uint256 treasureScehmaCount;
        mapping(uint256 => TreasureSchema) treasureSchema;
        mapping(uint256 => mapping(uint256 => uint256)) treasures;
    }


    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageItem() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageCoin() internal pure returns (CoinStorage storage ds) {
        bytes32 position = COIN_STORAGE_POSITION;
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

    function _createBasicEquipment(
        uint256 _slot,
        uint256 _value,
        uint256 _stat,
        uint256 _cost,
        uint256 _supply,
        string memory _name,
        string memory _uri
    ) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.basicEquipmentCount++;
        
        e.basicEquipmentSchema[e.basicEquipmentCount] = BasicEquipmentSchema(
            e.basicEquipmentCount, _slot, _value, _stat, _cost, _supply, _name, _uri
        );
    }

    function _purchaseBasicEquipment(uint256 _playerId, uint256 _equipmentSchemaId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= e.basicEquipmentSchema[_equipmentSchemaId].cost); //check user has enough gold
        require(e.basicEquipmentSupply[_equipmentSchemaId] < e.basicEquipmentSchema[_equipmentSchemaId].supply); //check bellow total supply
        e.equipmentCount++; //increment equipment count
        e.basicEquipmentSupply[_equipmentSchemaId]++; //increment total supply
        e.equipment[e.equipmentCount] = Equipment(
            e.equipmentCount,
            e.playerToEquipment[_playerId].length,
            e.basicEquipmentSchema[_equipmentSchemaId].slot,
            1,
            e.basicEquipmentSchema[_equipmentSchemaId].value,
            e.basicEquipmentSchema[_equipmentSchemaId].stat,
            _playerId,
            e.basicEquipmentSchema[_equipmentSchemaId].name,
            e.basicEquipmentSchema[_equipmentSchemaId].uri,
            false
        );
        e.playerToEquipment[_playerId].push(e.equipmentCount); //add to the player array
        c.goldBalance[msg.sender] -= e.basicEquipmentSchema[_equipmentSchemaId].cost;
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        c.goldBalance[feeRecipient] += e.basicEquipmentSchema[_equipmentSchemaId].cost; //increment fee account gold
    }

    function _createBasicCraft(uint256 _equipmenSchematId, uint256 _value, uint256 _cost, string memory _newName, string memory _uri) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.basicCraftCount++;
        e.basicCraft[e.basicCraftCount] = BasicCraft(
            e.basicCraftCount,
            e.basicEquipmentSchema[_equipmenSchematId].slot, 
            _value,
            _cost,
            e.basicEquipmentSchema[_equipmenSchematId].name,
            _newName,
            _uri
        );
    }

    function _createAdvancedCraft( 
        uint256 _treasureSchemaId,
        uint256 _slot,
        uint256 _value,
        uint256 _stat,
        uint256 _amount,
        string memory _oldName,
        string memory _newName,
        string memory _uri
    ) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.advancedCraftCount++;
        e.advancedCraft[e.advancedCraftCount] = AdvancedCraft(
            e.advancedCraftCount,
            _slot,
            _value,
            _stat,
            _amount,
            _treasureSchemaId,
            _oldName,
            _newName,
            _uri
        );
    }

    function _basicCraft(uint256 _playerId, uint256 _equipmentId, uint256 _craftId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you do not own this player"); //ownerOf player
        require(!e.equipment[_equipmentId].isEquiped, "must not be equipped"); //check that the hammer is not equipped
        BasicCraft storage basicCraft = e.basicCraft[_craftId];
        require(c.gemBalance[msg.sender] >= basicCraft.cost, "need more gem"); //check user has enough gem
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the hamemr
        require(
            keccak256(abi.encodePacked(e.equipment[_equipmentId].name))
                == keccak256(abi.encodePacked(basicCraft.oldName)),
            "not the same equipment name"
        );
        c.gemBalance[msg.sender] -= basicCraft.cost; //deduct 15 gem from the address' balance
        e.equipment[_equipmentId].rank++;
        e.equipment[_equipmentId].value = basicCraft.value;
        e.equipment[_equipmentId].name = basicCraft.newName;
        e.equipment[_equipmentId].uri = basicCraft.uri;
    }

    function _advancedCraft(uint256 _playerId, uint256 _advancedCraftId, uint256 _equipmentId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        TreasureStorage storage tr = diamondStorageTreasure();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you do not own this player"); //ownerOf player
        require(!e.equipment[_equipmentId].isEquiped, "must not be equipped"); //check that the hammer is not equipped
        AdvancedCraft storage advancedCraft = e.advancedCraft[_advancedCraftId];
        require(tr.treasures[advancedCraft.treasureSchemaId][_playerId] >= advancedCraft.amount); //player is owner of treasure;
        require(
            keccak256(abi.encodePacked(e.equipment[_equipmentId].name))
                == keccak256(abi.encodePacked(advancedCraft.oldName)),
            "not the same equipment name"
        );
        e.equipment[_equipmentId].rank++;
        e.equipment[_equipmentId].value = advancedCraft.value;
        e.equipment[_equipmentId].slot = advancedCraft.slot;
        e.equipment[_equipmentId].stat = advancedCraft.stat;
        e.equipment[_equipmentId].name = advancedCraft.newName;
        e.equipment[_equipmentId].uri = advancedCraft.uri;
        tr.treasures[advancedCraft.treasureSchemaId][_playerId] -= advancedCraft.amount;
    }

    function _updateBasicEquipmentScehma(
        uint256 basicEquipmentSchemaId,
        uint256 _slot,
        uint256 _value,
        uint256 _stat,
        uint256 _cost,
        string memory _name,
        string memory _uri
    ) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.basicEquipmentSchema[basicEquipmentSchemaId].slot = _slot;
        e.basicEquipmentSchema[basicEquipmentSchemaId].value = _value;
        e.basicEquipmentSchema[basicEquipmentSchemaId].stat = _stat;
        e.basicEquipmentSchema[basicEquipmentSchemaId].cost = _cost;
        e.basicEquipmentSchema[basicEquipmentSchemaId].name = _name;
        e.basicEquipmentSchema[basicEquipmentSchemaId].uri = _uri;
    }


    function _getPlayerToEquipment(uint256 _playerId) internal view returns (uint256[] memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.playerToEquipment[_playerId];
    }

    function _getEquipment(uint256 _equipmentId) internal view returns (Equipment memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.equipment[_equipmentId];
    }

    function _getBasicEquipmentCount() internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.basicEquipmentCount;
    }

    function _getBasicEquipmentScehma(uint256 _basicEquipmentSchemaId) internal view returns (BasicEquipmentSchema memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.basicEquipmentSchema[_basicEquipmentSchemaId];
    }

    function _getBasicCraftCount() internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.basicCraftCount;
    }

    function _getBasicCraft(uint256 _basicCraftId) internal view returns (BasicCraft memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.basicCraft[_basicCraftId];
    }

    function _getAdvancedCraftCount() internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.advancedCraftCount;
    }

    function _getAdvancedCraft(uint256 _advancedCraftId) internal view returns (AdvancedCraft memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.advancedCraft[_advancedCraftId];
    }

    function _getBasicEquipmentSupply(uint256 _basicEquipmentSchemaId) internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.basicEquipmentSupply[_basicEquipmentSchemaId];
    }

}

contract CraftFacet {
    event BasicEquipmentSchemaCreated(uint256 indexed _basicEquipmentSchemaId, uint256 indexed _value, string _uri, BasicEquipmentSchema _basicEQuipmentSchema);
    event BasicEquipmentSchemaUpdate(uint256 indexed _basicEquipmentSchemaId, uint256 indexed _value, string _uri, BasicEquipmentSchema _basicEQuipmentSchema);   
    event PurchaseBasicEquipment(uint256 indexed _playerId, uint256 _equipmentSchemaId);
    event CreateBasicCraft(uint256 indexed id, BasicCraft _basicCraft);
    event CreateAdvancedCraft(uint256 indexed id, AdvancedCraft _advancedCraft);
    event BasicCraftEvent(uint256 indexed _playerId, uint256 _equipmentId, uint256 _craftId);
    event AdvancedCraftEvent(uint256 indexed _playerId, uint256 _equipmentId, uint256 _advancedCraftId);

    function createBasicEquipment(
        uint256 _slot,
        uint256 _value,
        uint256 _stat,
        uint256 _cost,
        uint256 _supply,
        string memory _name,
        string memory _uri
    ) public {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        StorageLib._createBasicEquipment(_slot, _value, _stat, _cost, _supply, _name, _uri);
        uint256 id = StorageLib._getBasicEquipmentCount();
        emit BasicEquipmentSchemaCreated(id, _value, _uri, getBasicEquipmentSchema(id));
    }

    function purchaseBasicEquipment(uint256 _playerId, uint256 _equipmentSchemaId) public {
        StorageLib._purchaseBasicEquipment(_playerId, _equipmentSchemaId);
        emit PurchaseBasicEquipment(_playerId, _equipmentSchemaId);
    }

    function updateBasicEquipmentScehma(
        uint256 _basicEquipmentSchemaId,
        uint256 _slot,
        uint256 _value,
        uint256 _stat,
        uint256 _cost,
        string memory _name,
        string memory _uri
    ) public {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        StorageLib._updateBasicEquipmentScehma(_basicEquipmentSchemaId, _slot, _value, _stat, _cost, _name, _uri);
        emit BasicEquipmentSchemaCreated(_basicEquipmentSchemaId, _value, _uri, getBasicEquipmentSchema(_basicEquipmentSchemaId));
    }

    function getPlayerToEquipment(uint256 _playerId) public view returns (uint256[] memory) {
        return StorageLib._getPlayerToEquipment(_playerId);
    }

    function getEquipment(uint256 _equipmentId) public view returns (Equipment memory) {
        return StorageLib._getEquipment(_equipmentId);
    }

    function getBasicEquipmentCount() public view returns (uint256) {
        return StorageLib._getBasicEquipmentCount();
    }

    function getBasicEquipmentSchema(uint256 _basicEquipmentSchemaId) public view returns (BasicEquipmentSchema memory) {
        return StorageLib._getBasicEquipmentScehma(_basicEquipmentSchemaId);
    }

    function createBasicCraft(uint256 _equipmenSchematId, uint256 _value, uint256 _cost, string memory _newName, string memory _uri) public {
        StorageLib._createBasicCraft(_equipmenSchematId, _value, _cost, _newName, _uri);
        uint256 id = getBasicCraftCount();
        emit CreateBasicCraft(id, getBasicCraft(id));
    }

    function basicCraft(uint256 _playerId, uint256 _equipmentId, uint256 _craftId) public {
        StorageLib._basicCraft(_playerId, _equipmentId, _craftId);
        emit BasicCraftEvent(_playerId, _equipmentId, _craftId);
    }

    function getBasicCraftCount() public view returns (uint256) {
        return StorageLib._getBasicCraftCount();
    }

    function getBasicCraft(uint256 _basicCraftId) public view returns (BasicCraft memory) {
        return StorageLib._getBasicCraft(_basicCraftId);
    }


    function createAdvancedCraft(uint256 _treasureSchemaId,uint256 _slot,uint256 _value,uint256 _stat,uint256 _amount,string memory _oldName,string memory _newName,string memory _uri) public {
        StorageLib._createAdvancedCraft(_treasureSchemaId, _slot, _value, _stat, _amount, _oldName, _newName, _uri);
        uint256 id = getAdvancedCraftCount();
        emit CreateAdvancedCraft(id, getAdvancedCraft(id));
    }

    function advancedCraft(uint256 _playerId, uint256 _advancedCraftId, uint256 _equipmentId) public {
        StorageLib._advancedCraft(_playerId, _advancedCraftId, _equipmentId);
        emit AdvancedCraftEvent(_playerId, _equipmentId, _advancedCraftId);
    }

    function getAdvancedCraftCount() public view returns (uint256) {
        return StorageLib._getAdvancedCraftCount();
    }

    function getAdvancedCraft(uint256 _advancedCraftId) public view returns (AdvancedCraft memory) {
        return StorageLib._getAdvancedCraft(_advancedCraftId);
    }

    function getBasicEquipmentSupply(uint256 _basicEquipmentSchemaId) public view returns (uint256) {
        return StorageLib._getBasicEquipmentSupply(_basicEquipmentSchemaId);
    }


    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}