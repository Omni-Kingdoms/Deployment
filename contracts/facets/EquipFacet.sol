// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

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

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageEquipment() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _increaseStats(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        Equipment storage equipment = e.equipment[_equipmentId];
        uint256 stat = equipment.stat;
        if (stat == 0) {
            //if strength
            s.players[_playerId].strength += equipment.value;
        } else if (stat == 1) {
            //if health
            s.players[_playerId].health += equipment.value;
            s.players[_playerId].currentHealth += equipment.value;
        } else if (stat == 2) {
            //if agility
            s.players[_playerId].agility += equipment.value;
        } else if (stat == 3) {
            //if magic
            s.players[_playerId].magic += equipment.value;
        } else if (stat == 4) {
            //if defense
            s.players[_playerId].defense += equipment.value;
        } else if (stat == 5) {
            //if maxMana
            s.players[_playerId].maxMana += equipment.value;
            s.players[_playerId].mana += equipment.value;
        } else {
            // must be luck
            s.players[_playerId].luck += equipment.value;
        }
    }

    function _decreaseStats(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        Equipment storage equipment = e.equipment[_equipmentId];
        uint256 stat = equipment.stat;
        if (stat == 0) {
            //if strength
            s.players[_playerId].strength -= equipment.value;
        } else if (stat == 1) {
            //if health
            s.players[_playerId].health -= equipment.value;
            if (s.players[_playerId].currentHealth <= equipment.value) {
                s.players[_playerId].currentHealth = 0;
            } else {
                s.players[_playerId].currentHealth -= equipment.value;
            }
        } else if (stat == 2) {
            //if agility
            s.players[_playerId].agility -= equipment.value;
        } else if (stat == 3) {
            //if magic
            s.players[_playerId].magic -= equipment.value;
        } else if (stat == 4) {
            //if defense
            s.players[_playerId].defense -= equipment.value;
        } else if (stat == 5) {
            //if maxMana
            s.players[_playerId].maxMana -= equipment.value;
            if (s.players[_playerId].mana <= equipment.value) {
                s.players[_playerId].mana = 0;
            } else {
                s.players[_playerId].mana -= equipment.value;
            }
        } else {
            // must be luck
            s.players[_playerId].luck -= equipment.value;
        }
    }

    function _equip(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        uint256 slot = e.equipment[_equipmentId].slot;
        if (slot == 0) { //head
            _equipHead(_playerId, _equipmentId);
        } else if (slot == 1) { //body
            _equipBody(_playerId, _equipmentId);
        } else if (slot == 2 || slot == 3) { //Hand
            if (s.players[_playerId].slot.leftHand == 0) {
                _equipLeftHand(_playerId, _equipmentId);
            } else  {
                _equipRightHand(_playerId, _equipmentId);
            }
        } else if (slot == 4) { //pants
            _equipPants(_playerId, _equipmentId);
        } else if (slot == 5) { //pants
            _equipFeet(_playerId, _equipmentId);
        } else if (slot == 6) {
            _equipNeck(_playerId, _equipmentId);
        } else {
            return;
        }
    }

    function _unequip(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        uint256 slot = e.equipment[_equipmentId].slot;
        if (slot == 0) { //head
            _unequipHead(_playerId, _equipmentId);
        } else if (slot == 1) { //body
            _unequipBody(_playerId, _equipmentId);
        } else if (slot == 2) { //leftHand
            _unequipLeftHand(_playerId, _equipmentId);
        } else if (slot == 3) { //rightHand
            _unequipRightHand(_playerId, _equipmentId);
        } else if (slot == 4) { //pants
            _unequipPants(_playerId, _equipmentId);
        } else if (slot == 5) { //pants
            _unequipFeet(_playerId, _equipmentId);
        } else {
            _unequipNeck(_playerId, _equipmentId);
        }
    }

    function _equipHead(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 0); //require item head
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.head == 0); //require that player doesnt have a head item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.head = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipHead(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 0); //require item head
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.head == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.head = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipBody(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 1); //require item body
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.body == 0); //require that player doesnt have a body item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.body = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipBody(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 1); //require item body
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.body == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.body = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipLeftHand(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 2 || equipment.slot == 3); //require item leftHand
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.leftHand == 0); //require that player doesnt have a leftHand item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.leftHand = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipLeftHand(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 2 || equipment.slot == 3); //require item leftHand or left hand
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.leftHand == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.leftHand = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipRightHand(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 3 || equipment.slot == 2); //require item rightHand
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.rightHand == 0); //require that player doesnt have a rightHand item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.rightHand = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipRightHand(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 3 || equipment.slot == 2); //require item rightHand
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.rightHand == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.rightHand = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipPants(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 4); //require item pants
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.pants == 0); //require that player doesnt have a pants item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.pants = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipPants(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 4); //require item pants
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.pants == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.pants = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipFeet(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 5); //require item feet
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.feet == 0); //require that player doesnt have a pants item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.feet = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipFeet(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 5); //require item feet
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.feet == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.feet = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }

    function _equipNeck(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(e.equipment[_equipmentId].owner == _playerId); //check that the player is the onwer of the equipment
        require(equipment.slot == 6); //require item feet
        require(!equipment.isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.neck == 0); //require that player doesnt have a pants item on
        e.equipment[_equipmentId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.neck = equipment.id; //equip the item to the player
        _increaseStats(_playerId, _equipmentId);
    }
    function _unequipNeck(uint256 _playerId, uint256 _equipmentId) internal {
        EquipmentStorage storage e = diamondStorageEquipment();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        Equipment storage equipment = e.equipment[_equipmentId];
        require(equipment.slot == 6); //require item neck
        require(equipment.isEquiped); //require item is equiped
        require(s.players[_playerId].slot.neck == _equipmentId); //require that player has the same item on
        e.equipment[_equipmentId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.neck = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _equipmentId);
    }


}

contract EquipFacet {
    event ItemEquiped(address indexed _owner, uint256 indexed _playerId, uint256 indexed _equipmentId);
    event ItemUnequiped(address indexed _owner, uint256 indexed _playerId, uint256 indexed _equipmentId);

    function equip(uint256 _playerId, uint256 _equipmentId) public {
        StorageLib._equip(_playerId, _equipmentId);
        emit ItemEquiped(msg.sender, _playerId, _equipmentId);
    }
    function unequip(uint256 _playerId, uint256 _equipmentId) public {
        StorageLib._unequip(_playerId, _equipmentId);
        emit ItemUnequiped(msg.sender, _playerId, _equipmentId);
    }


    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
