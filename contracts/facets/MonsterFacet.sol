// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";
import "../libraries/PlayerSlotLib.sol";
import "../libraries/TreasureLib.sol";

struct BasicEquipmentSchema {
    uint256 basicEquipmentSchemaId;
    uint256 slot;
    uint256 value;
    uint256 stat;
    uint256 cost;
    string name;
    string uri;
}

// StatusCodes {
//     0: idle;
//     1: combatTrain;
//     2: goldQuest;
//     3: manaTrain;
//     4: Arena;
//     5: gemQuest;
// }

struct BasicCraft {
    uint256 id;
    uint256 slot;
    uint256 value;
    uint256 cost;
    string oldName;
    string newName;
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

// stat {
//     0: strength;
//     1: health;
//     2: agility;
//     3: magic;
//     4: defense;
//     5: luck;
// }


struct BasicMonster {
    uint256 basicMonsterId;
    uint256 xpReward;
    uint256 damage;
    uint256 hp;
    uint256 cooldown;
    string name;
    string uri;
}

struct TreasureMonster {
    uint256 treasureMonsterId;
    uint256 xpReward;
    uint256 damage;
    uint256 hp;
    uint256 cooldown;
    uint256 slot;
    uint256 equipmentSchemaId;
    uint256 treasureSchemaId;
    string name;
    string uri;
}

library StorageMonsterLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant QUEST_STORAGE_POSITION = keccak256("quest.test.storage.a");
    bytes32 constant MONSTER_STORAGE_POSITION = keccak256("monster.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant EQUIPMENT_STORAGE_POSITION = keccak256("equipment.test.storage.a");
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

    struct QuestStorage {
        uint256 questCounter;
        mapping(uint256 => uint256) goldQuest;
        mapping(uint256 => uint256) gemQuest;
        mapping(uint256 => uint256) totemQuest;
        mapping(uint256 => uint256) diamondQuest;
        mapping(uint256 => uint256) cooldowns;
        mapping(uint256 => uint256) gravityHammerQuestCooldown;
    }

    struct MonsterStorage {
        uint256 basicMonsterCounter;
        uint256 treasureMonsterCounter;
        mapping(uint256 => mapping(uint256 => uint256)) basicMonsterCooldowns;
        mapping(uint256 => BasicMonster) basicMonsters;
        mapping(uint256 => mapping(uint256 => uint256)) treasureMonsterCooldowns;
        mapping(uint256 => TreasureMonster) treasureMonsters;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
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

    function diamondStorageQuest() internal pure returns (QuestStorage storage ds) {
        bytes32 position = QUEST_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function diamondStorageMonster() internal pure returns (MonsterStorage storage ds) {
        bytes32 position = MONSTER_STORAGE_POSITION;
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

    function diamondStorageEquipment() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
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

    function _createBasicMonster(
        uint256 _xpReward,
        uint256 _damage,
        uint256 _hp,
        uint256 _cooldown,
        string memory _name,
        string memory _uri
    ) internal {
        MonsterStorage storage m = diamondStorageMonster();
        m.basicMonsterCounter++; //monster counter increment
        m.basicMonsters[m.basicMonsterCounter] = BasicMonster(m.basicMonsterCounter,_xpReward,_damage,_hp,_cooldown,_name,_uri); //create the monster
    }

    function _fightBasicMonster(uint256 _playerId, uint256 _monsterId) internal {
        MonsterStorage storage m = diamondStorageMonster();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        uint256 damage;        
        s.players[_playerId].defense >= m.basicMonsters[_monsterId].damage ? damage = 1 : damage = m.basicMonsters[_monsterId].damage - s.players[_playerId].defense + 1;
        require(s.players[_playerId].currentHealth > damage, "not enough hp"); //hp check
        uint256 timer;
        s.players[_playerId].agility >= m.basicMonsters[_monsterId].cooldown/2  ? timer = m.basicMonsters[_monsterId].cooldown/2  : timer = m.basicMonsters[_monsterId].cooldown - s.players[_playerId].agility + 10;
        require(block.timestamp >= m.basicMonsterCooldowns[_monsterId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
        require(s.players[_playerId].strength >=  m.basicMonsters[_monsterId].hp, "not strong enough"); //require strong enough to kill monster
        s.players[_playerId].xp += m.basicMonsters[_monsterId].xpReward; //give the player xp
        s.players[_playerId].currentHealth -= damage; //deduct damage
        m.basicMonsterCooldowns[_monsterId][_playerId] = block.timestamp; //reset timmmer
    }

    function _createTreasureMonster(
        uint256 _xpReward,
        uint256 _damage,
        uint256 _hp,
        uint256 _cooldown,
        uint256 _equipmentScehmaId,
        uint256 _treasureScehmaId,
        string memory _name,
        string memory _uri
    ) internal {
        MonsterStorage storage m = diamondStorageMonster();
        EquipmentStorage storage e = diamondStorageEquipment();
        m.treasureMonsterCounter++; //monster counter increment
        m.treasureMonsters[m.basicMonsterCounter] = TreasureMonster(
            m.treasureMonsterCounter,
            _xpReward,
            _damage,
            _hp,
            _cooldown,
            e.basicEquipmentSchema[_equipmentScehmaId].slot,
            _equipmentScehmaId,
            _treasureScehmaId,
            _name,
            _uri); //create the monster
    }

    


    // function _dragonQuest(uint256 _playerId) internal returns (bool) {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     MonsterStorage storage m = diamondStorageMonster();
    //     EquipmentStorage storage e = diamondStorageEquipment();
    //     TreasureStorage storage t = diamondStorageTreasure();
    //     require(s.players[_playerId].status == 0); //make sure player is idle
    //     require(s.owners[_playerId] == msg.sender); //ownerOf
    //     require(block.timestamp >= m.dragonCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
    //     require(
    //         keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.head].name))
    //             == keccak256(abi.encodePacked("WizHat")),
    //         "not wearing hat"
    //     ); // must have wizard hat on
    //     m.dragonCooldown[_playerId] = block.timestamp; //reset cooldown
    //     if (_random(_playerId) % 20 >= 19) {
    //         //5%
    //         t.treasureCount++;
    //         t.treasures[t.treasureCount] = Treasure(t.treasureCount, 2, t.playerToTreasure[_playerId].length, "Dscale"); //create treasure and add it main map
    //         t.playerToTreasure[_playerId].push(t.treasureCount); //push
    //         t.owners[t.treasureCount] = msg.sender; //set the user as the owner of the item;
    //         s.players[_playerId].xp++; //increment xp
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // function _dragonGateQuest(uint256 _playerId) internal returns (bool) {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     MonsterStorage storage m = diamondStorageMonster();
    //     EquipmentStorage storage e = diamondStorageEquipment();
    //     TreasureStorage storage t = diamondStorageTreasure();
    //     require(s.players[_playerId].status == 0); //make sure player is idle
    //     require(s.owners[_playerId] == msg.sender); //ownerOf
    //     require(block.timestamp >= m.dragonCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
    //     require(
    //         keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("Guitar")) || 
    //         keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.leftHand].name)) == keccak256(abi.encodePacked("Guitar"))
    //     );
    //     m.dragonCooldown[_playerId] = block.timestamp; //reset cooldown
    //     uint256 mod = _random(_playerId) % 20;
    //     if (s.players[_playerId].strength > 100 && s.players[_playerId].strength < 200) {
    //         mod += 2;
    //     } else if (s.players[_playerId].strength > 200 && s.players[_playerId].strength < 300) {
    //         mod += 4;
    //     }
    //     if (mod >= 19) {
    //         //5%
    //         t.treasureCount++;
    //         t.treasures[t.treasureCount] = Treasure(t.treasureCount, 1, t.playerToTreasure[_playerId].length, "Degg"); //create treasure and add it main map
    //         t.playerToTreasure[_playerId].push(t.treasureCount); //push
    //         t.owners[t.treasureCount] = msg.sender; //set the user as the owner of the item;
    //         s.players[_playerId].xp++; //increment xp
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // function _gravityHammerQuest(uint256 _playerId) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     QuestStorage storage q = diamondStorageQuest();
    //     EquipmentStorage storage e = diamondStorageEquipment();
    //     require(s.players[_playerId].status == 0); //make sure player is idle
    //     require(s.owners[_playerId] == msg.sender); //ownerOf
    //     require(block.timestamp >= q.gravityHammerQuestCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
    //     require(
    //         keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("GHammer")) || 
    //         keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.leftHand].name)) == keccak256(abi.encodePacked("GHammer"))
    //     );
    //     q.gravityHammerQuestCooldown[_playerId] = block.timestamp; //reset cooldown
    //     if (keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("GHammer"))) { 
    //         e.equipment[s.players[_playerId].slot.rightHand].value += 1; 
    //     } else {
    //         e.equipment[s.players[_playerId].slot.leftHand].value += 1;
    //     }
    //     q.gravityHammerQuestCooldown[_playerId] = block.timestamp; //reset timer
    //     s.players[_playerId].strength += 1;
    // }


    function _random(uint256 _nonce) internal returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        q.questCounter++;
        //return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _nonce, q.questCounter)));
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _nonce, q.questCounter)));
    }

    function _getBasicMonsterCounter() internal view returns (uint256) {
        MonsterStorage storage m = diamondStorageMonster();
        return (m.basicMonsterCounter);
    }

    function _getBasicMonster(uint256 _monsterId) internal view returns (BasicMonster memory) {
        MonsterStorage storage m = diamondStorageMonster();
        return m.basicMonsters[_monsterId];
    }

    function _getBasicMonsterCooldown(uint256 _playerId, uint256 _monsterId) internal view returns (uint256) {
        MonsterStorage storage m = diamondStorageMonster();
        return m.basicMonsterCooldowns[_monsterId][_playerId];
    }

}

contract MonsterFacet {

    event DragonQuest(uint256 indexed _playerId);
    event CreateBasicMonster(uint256 indexed _monsterId);
    event FightBasicMonster(uint256 indexed _monsterId, uint256 _playerId);

    // function dragonQuest(uint256 _playerId) external returns (bool result) {
    //     result = StorageMonsterLib._dragonQuest(_playerId);
    //     if (result) emit DragonQuest(_playerId);
    //     return result;
    // }

    function createBasicMonster(uint256 _xpReward, uint256 _damage, uint256 _hp, uint256 _cooldown, string memory _name, string memory _uri) public {
        //address createAccount = payable(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        //require(msg.sender == createAccount);
        StorageMonsterLib._createBasicMonster(_xpReward, _damage, _hp, _cooldown, _name, _uri);
        emit CreateBasicMonster(StorageMonsterLib._getBasicMonsterCounter());
    }

    function fightBasicMonster(uint256 _playerId, uint256 _monsterId) public {
        StorageMonsterLib._fightBasicMonster(_playerId, _monsterId);
        emit FightBasicMonster(_monsterId, _playerId);
    }

    function getMonsterCounter() public view returns (uint256) {
        return StorageMonsterLib._getBasicMonsterCounter();
    }

    function getBasicMonster(uint256 _monsterId) public view returns (BasicMonster memory) {
        return StorageMonsterLib._getBasicMonster(_monsterId);
    }

    function getBasicMonsterCooldown(uint256 _playerId, uint256 _monsterId) public view returns (uint256) {
        return StorageMonsterLib._getBasicMonsterCooldown(_playerId, _monsterId);
    }







    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}