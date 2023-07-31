// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";


struct BasicEquipment {
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
        mapping(uint256 => BasicEquipment) basicEquipment;
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
        e.basicEquipment[e.basicEquipmentCount] = BasicEquipment(
            _slot, _value, _stat, _cost, _name, _uri
        );
    }

    function _purhcaseBasicEquipment(uint256 _playerId, uint256 _equipmentId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= e.basicEquipment[_equipmentId].cost); //check user has enough gold
        e.equipmentCount++; //increment equipment count
        e.equipment[e.equipmentCount] = Equipment(
            _equipmentId,
            e.playerToEquipment[_playerId].length,
            e.basicEquipment[_equipmentId].slot,
            1,
            e.basicEquipment[_equipmentId].value,
            e.basicEquipment[_equipmentId].stat,
            _playerId,
            e.basicEquipment[_equipmentId].name,
            e.basicEquipment[_equipmentId].uri,
            false
        );
        e.playerToEquipment[_playerId].push(e.equipmentCount); //add to the player array
    }

    function _createBasicCraft(uint256 _equipmentId, uint256 _value, uint256 _cost, string memory _newName, string memory _uri) internal {
        EquipmentStorage storage e = diamondStorageItem();
        e.basicCraftCount++;
        e.basicCraft[e.basicCraftCount] = BasicCraft(
            e.basicEquipment[_equipmentId].slot, 
            _value,
            _cost,
            e.basicEquipment[_equipmentId].name,
            _newName,
            _uri
        );
    }

    function _basicCraft(uint256 _playerId, uint256 _equipmentId, uint256 _craftId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
    }







    // function _craftGravityHammer(uint256 _playerId, uint256 _itemId, string memory _uri) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     EquipmentStorage storage e = diamondStorageItem();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_playerId].status == 0, "must be idle"); //make sure player is idle
    //     require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
    //     require(e.owners[_itemId] == _playerId); //check that the player is the onwer of the hamemr
    //     require(!e.equipment[_itemId].isEquiped, "must not be equipped"); //check that the hammer is not equipped
    //     require(
    //         keccak256(abi.encodePacked(e.equipment[_itemId].name))
    //             == keccak256(abi.encodePacked("WHammer")),
    //         "this is not a war hammer"
    //     );
    //     require(c.gemBalance[msg.sender] >= 15); //check user has enough gem
    //     c.gemBalance[msg.sender] -= 15; //deduct 15 gem from the address' balance

    //     uint256 keyToDelete = e.equipment[_itemId].pointer; //sets the index to delete as the desired key
    //     uint256 keyToMove = e.playerToEquipment[_playerId].length - 1; //gets the index of the last equipment that is owned by the player
    //     e.playerToEquipment[_playerId][keyToDelete] = keyToMove; //the id in the playerToEquipment is replaced w the last index key 
    //     e.equipment[e.playerToEquipment[_playerId][keyToDelete]].pointer = keyToDelete; //reset the pointer
    //     e.playerToEquipment[_playerId].pop(); //remove the last key item
    //     delete e.playerToEquipment[_itemId]; //delete the item

    //     e.equipmentCount++; //increment equipmentCount
    //     e.owners[e.equipmentCount] = _playerId; //set owner to playerId
    //     e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 2, 1, 10, 0, _playerId, "GHammer", _uri, false);
    //     e.playerToEquipment[_playerId].push(e.equipmentCount);
    // }


    // function _craftArmor(uint256 _playerId, string memory _uri) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     EquipmentStorage storage e = diamondStorageItem();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_playerId].status == 0); //make sure player is idle
    //     require(s.owners[_playerId] == msg.sender); //ownerOf
    //     require(c.goldBalance[msg.sender] >= 10); //check user has enough gold
    //     require(s.players[_playerId].mana >= 2); //make sure player has at least 2 mana
    //     c.goldBalance[msg.sender] -= 10; //deduct 10 gold from the address' balance
    //     s.players[_playerId].mana -= 2; //deduct 2 mana from the player
    //     e.equipmentCount++; //increment equipmentCount
    //     e.owners[e.equipmentCount] = _playerId; //set owner to playerId
    //     e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 1, 1, 10, 1, _playerId, "Armor", _uri, false);
    //     e.playerToEquipment[_playerId].push(e.equipmentCount);
    // }




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