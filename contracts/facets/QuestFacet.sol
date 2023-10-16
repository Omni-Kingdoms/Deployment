// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
//import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";
//import {RandomnesFacet} from "./RandomnessFacet.sol";


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




library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant QUEST_STORAGE_POSITION = keccak256("quest.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
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
    }

    struct QuestStorage {
        uint256 questCounter;
        mapping(uint256 => uint256) goldQuest;
        mapping(uint256 => uint256) gemQuest;
        mapping(uint256 => uint256) totemQuest;
        mapping(uint256 => uint256) diamondQuest;       
        mapping(uint256 => uint256) cooldowns;
    }

    struct CoinStorage {
        uint256 goldCount;
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


    function _startQuestGold(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_tokenId].status == 0); //make sure player is idle
        require(s.owners[_tokenId] == msg.sender); //ownerOf
        require(c.goldCount <= 10000000); // less than one 10M
        c.goldCount++;
        s.players[_tokenId].status = 2; //set quest status
        q.goldQuest[_tokenId] = block.timestamp; //set start time
    }

    function _endQuestGold(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        QuestStorage storage q = diamondStorageQuest();
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //onlyOwner
        require(s.players[_playerId].status == 2, "Dog, you are not gold questing"); //currently gold questing
        uint256 timer;
        s.players[_playerId].agility >= 600 ? timer = 600 : timer = 610 - s.players[_playerId].agility;
        require(block.timestamp >= q.goldQuest[_playerId] + timer, "it's too early to pull out");
        s.players[_playerId].status = 0; //set back to idle
        delete q.goldQuest[_playerId]; //remove the start time
        c.goldBalance[msg.sender] += 10; //mint 10 gold
    }

    function _startQuestGem(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        uint256 timer;
        s.players[_playerId].agility >= 300 ? timer = 300 : timer = 610 - s.players[_playerId].agility;
        require(block.timestamp >= q.cooldowns[_playerId] + timer); //make sure that they have waited 5 mins for gem
        s.players[_playerId].status = 5; //set gemQuest status
        q.gemQuest[_playerId] = block.timestamp; //set start time
    }

    function _endQuestGem(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        QuestStorage storage q = diamondStorageQuest();
        require(s.owners[_playerId] == msg.sender);
        require(s.players[_playerId].status == 5);
        uint256 timer;
        s.players[_playerId].agility >= 300 ? timer = 300 : timer = 610 - s.players[_playerId].agility;
        require(
            block.timestamp >= q.gemQuest[_playerId] + timer, //must wait 5 mins
            "it's too early to pull out"
        );
        s.players[_playerId].status = 0; //set back to idle
        delete q.gemQuest[_playerId]; //remove the start time
        c.gemBalance[msg.sender]++; //mint one gem
        q.cooldowns[_playerId] = block.timestamp; //set the cooldown to the current time
    }

    function _getGoldBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.goldBalance[_address];
    }

    function _getGemBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.gemBalance[_address];
    }

    function _getGoldStart(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.goldQuest[_playerId];
    }

    function _getGemStart(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.gemQuest[_playerId];
    }

    function _getCooldown(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.cooldowns[_playerId];
    }


    function getGold() internal {
        CoinStorage storage c = diamondStorageCoin();
        c.goldBalance[msg.sender] += 100;
    }
}

contract QuestFacet {
    event BeginQuesting(address indexed _playerAddress, uint256 _id);
    event EndQuesting(address indexed _playerAddress, uint256 _id);

    function startQuestGold(uint256 _tokenId) external {
        StorageLib._startQuestGold(_tokenId);
        emit BeginQuesting(msg.sender, _tokenId);
    }

    function endQuestGold(uint256 _tokenId) external {
        StorageLib._endQuestGold(_tokenId);
        emit EndQuesting(msg.sender, _tokenId);
    }

    function getGoldBalance(address _address) public view returns (uint256) {
        return StorageLib._getGoldBalance(_address);
    }

    function startQuestGem(uint256 _tokenId) external {
        StorageLib._startQuestGem(_tokenId);
        emit BeginQuesting(msg.sender, _tokenId);
    }

    function endQuestGem(uint256 _tokenId) external {
        StorageLib._endQuestGem(_tokenId);
        emit EndQuesting(msg.sender, _tokenId);
    }


    function getGemBalance(address _address) public view returns (uint256) {
        return StorageLib._getGemBalance(_address);
    }

    function getGoldStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGoldStart(_playerId);
    }

    function getGemStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGemStart(_playerId);
    }

    function getCooldown(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getCooldown(_playerId);
    }

    function getGold() public {
        StorageLib.getGold();
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}