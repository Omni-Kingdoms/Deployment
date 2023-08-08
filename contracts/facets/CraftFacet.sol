// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";


struct BasicEquipmentSchema {
    uint256 basicEquipmentSchemaId;
    uint256 slot;
    uint256 value;
    uint256 stat;
    uint256 cost;
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
    uint256 slot;
    uint256 cost;
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

struct Treasure {
    uint256 id;
    uint256 rank;
    uint256 pointer;
    string name;
}

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
        mapping(uint256 => Equipment) equipment;
        uint256 basicCraftCount;
        mapping(uint256 => BasicCraft) basicCraft;
        mapping(uint256 => uint256[]) playerToEquipment;
    }

    struct PotionStorage {
        mapping(uint256 => address) timePotion;
        mapping(address => uint256) healthPotion;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct TreasureStorage {
        uint256 treasureCount;
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
        string memory _name,
        string memory _uri
    ) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.basicEquipmentCount++;
        e.basicEquipmentSchema[e.basicEquipmentCount] = BasicEquipmentSchema(
            e.basicEquipmentCount, _slot, _value, _stat, _cost, _name, _uri
        );
    }

    function _purchaseBasicEquipment(uint256 _playerId, uint256 _equipmentSchemaId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= e.basicEquipmentSchema[_equipmentSchemaId].cost); //check user has enough gold
        e.equipmentCount++; //increment equipment count
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


    function _getPlayerToEquipment(uint256 _playerId) internal view returns (uint256[] memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.playerToEquipment[_playerId];
    }

    function _getEquipment(uint256 _equipmentId) internal view returns (Equipment memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.equipment[_equipmentId];
    }

    function _getEquipmentCount() internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.equipmentCount;
    }

    // function _mintCoins() internal {
    //     CoinStorage storage c = diamondStorageCoin();
    //     c.goldBalance[msg.sender] += 100; //mint one gold
    //     c.gemBalance[msg.sender] += 100; //mint one gold
    //     c.diamondBalance[msg.sender] += 100; //mint one gold
    //     c.totemBalance[msg.sender] += 100; //mint one gold
    // }

    // function _getCoinBalances(address _player)
    //     internal
    //     view
    //     returns (uint256 goldBalance, uint256 gemBalance, uint256 totemBalance, uint256 diamondBalance)
    // {
    //     CoinStorage storage c = diamondStorageCoin();
    //     goldBalance = c.goldBalance[_player];
    //     gemBalance = c.gemBalance[_player];
    //     totemBalance = c.totemBalance[_player];
    //     diamondBalance = c.diamondBalance[_player];
    // }
}

contract CraftFacet {
    event ItemCrafted(address indexed _owner, uint256 _player);


    // function craftArmor(uint256 _tokenId) external {
    //     StorageLib._craftArmor(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftHelmet(uint256 _tokenId) external {
    //     StorageLib._craftHelmet(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftSorcerShoes(uint256 _tokenId) external {
    //     StorageLib._craftSorcerShoes(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftWizardHat(uint256 _tokenId) external {
    //     StorageLib._craftWizardHat(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function getItems(address _address) public view returns (uint256[] memory items) {
    //     items = StorageLib._getItems(_address);
    // }

    // function getItem(uint256 _itemId) public view returns (Item memory item) {
    //     item = StorageLib._getItem(_itemId);
    // }

    // function getItemCount() public view returns (uint256 count) {
    //     count = StorageLib._getItemCount();
    // }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}