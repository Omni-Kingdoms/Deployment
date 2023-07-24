// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

// StatusCodes {
//     0: idle;
//     1: combatTrain;
//     2: goldQuest;
//     3: manaTrain;
//     4: Arena;
//     5: gemQuest;
// }

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

struct Treasure {
    uint256 id;
    uint256 rank;
    uint256 pointer;
    string name;
}

library StorageLib {
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
        uint256 monsterCounter;
        uint256[] orcParty;
        mapping(uint256 => uint256) dragonCooldown;
        mapping(uint256 => uint256) goblinCooldown;
        mapping(uint256 => uint256) orcCooldown;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct EquipmentStorage {
        uint256 equipmentCount;
        mapping(uint256 => uint256) owners; //maps equipment id to player id
        mapping(uint256 => Equipment) equipment;
        mapping(uint256 => uint256[]) playerToEquipment;
        mapping(uint256 => uint256) cooldown;
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

    function _fightGoblin(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        MonsterStorage storage m = diamondStorageMonster();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf


        require(block.timestamp >= m.dragonCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);

    }


    function _dragonQuest(uint256 _playerId) internal returns (bool) {
        PlayerStorage storage s = diamondStoragePlayer();
        MonsterStorage storage m = diamondStorageMonster();
        EquipmentStorage storage e = diamondStorageEquipment();
        TreasureStorage storage t = diamondStorageTreasure();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(block.timestamp >= m.dragonCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
        require(
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.head].name))
                == keccak256(abi.encodePacked("WizHat")),
            "not wearing hat"
        ); // must have wizard hat on
        m.dragonCooldown[_playerId] = block.timestamp; //reset cooldown
        if (_random(_playerId) % 20 >= 19) {
            //5%
            t.treasureCount++;
            t.treasures[t.treasureCount] = Treasure(t.treasureCount, 2, t.playerToTreasure[_playerId].length, "Dscale"); //create treasure and add it main map
            t.playerToTreasure[_playerId].push(t.treasureCount); //push
            t.owners[t.treasureCount] = msg.sender; //set the user as the owner of the item;
            s.players[_playerId].xp++; //increment xp
            return true;
        } else {
            return false;
        }
    }

    function _dragonGateQuest(uint256 _playerId) internal returns (bool) {
        PlayerStorage storage s = diamondStoragePlayer();
        MonsterStorage storage m = diamondStorageMonster();
        EquipmentStorage storage e = diamondStorageEquipment();
        TreasureStorage storage t = diamondStorageTreasure();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(block.timestamp >= m.dragonCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
        require(
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("Guitar")) || 
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.leftHand].name)) == keccak256(abi.encodePacked("Guitar"))
        );
        m.dragonCooldown[_playerId] = block.timestamp; //reset cooldown
        uint256 mod = _random(_playerId) % 20;
        if (s.players[_playerId].strength > 100 && s.players[_playerId].strength < 200) {
            mod += 2;
        } else if (s.players[_playerId].strength > 200 && s.players[_playerId].strength < 300) {
            mod += 4;
        }
        if (mod >= 19) {
            //5%
            t.treasureCount++;
            t.treasures[t.treasureCount] = Treasure(t.treasureCount, 1, t.playerToTreasure[_playerId].length, "Degg"); //create treasure and add it main map
            t.playerToTreasure[_playerId].push(t.treasureCount); //push
            t.owners[t.treasureCount] = msg.sender; //set the user as the owner of the item;
            s.players[_playerId].xp++; //increment xp
            return true;
        } else {
            return false;
        }
    }

    function _gravityHammerQuest(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        EquipmentStorage storage e = diamondStorageEquipment();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(block.timestamp >= q.gravityHammerQuestCooldown[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
        require(
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("GHammer")) || 
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.leftHand].name)) == keccak256(abi.encodePacked("GHammer"))
        );
        q.gravityHammerQuestCooldown[_playerId] = block.timestamp; //reset cooldown
        if (keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.rightHand].name)) == keccak256(abi.encodePacked("GHammer"))) { 
            e.equipment[s.players[_playerId].slot.rightHand].value += 1; 
        } else {
            e.equipment[s.players[_playerId].slot.leftHand].value += 1;
        }
        q.gravityHammerQuestCooldown[_playerId] = block.timestamp; //reset timer
        s.players[_playerId].strength += 1;
    }

    function _random(uint256 _nonce) internal returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        q.questCounter++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _nonce, q.questCounter)));
    }


    function _getCooldown(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.cooldowns[_playerId];
    }

}

contract MonsterFacet {

    event DragonQuest(uint256 indexed _playerId);

    function dragonQuest(uint256 _playerId) external returns (bool result) {
        result = StorageLib._dragonQuest(_playerId);
        if (result) emit DragonQuest(_playerId);
        return result;
    }



    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}