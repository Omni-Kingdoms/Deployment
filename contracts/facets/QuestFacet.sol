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

struct GoldQuestSchema {
    uint256 GoldQuestSchemaId;
    uint256 reward;
    uint256 maxReward;
    uint256 level;
    uint256 damage;
    uint256 time;
}




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
        uint256 goldQuestCounter;
        mapping(uint256 => mapping(uint256 => uint256)) goldQuestStart;
        mapping(uint256 => GoldQuestSchema) goldQuests;
        mapping(uint256 => uint256) currentQuest;
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

    function _createGoldQuest(uint256 _reward, uint256 _maxReward, uint256 _level, uint256 _damage, uint256 _time) internal {
        QuestStorage storage q = diamondStorageQuest();
        q.goldQuestCounter++; //increment for new quest
        q.goldQuests[q.goldQuestCounter] = GoldQuestSchema(
            q.goldQuestCounter,
            _reward,
            _maxReward,
            _level,
            _damage,
            _time
        );
    }

    function _startQuestGold(uint256 _playerId, uint256 _goldQuestSchemaId) internal {
        QuestStorage storage q = diamondStorageQuest();
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        require(q.goldQuests[_goldQuestSchemaId].maxReward != 0);
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        require(c.goldBalance[feeRecipient] >= 10000 + q.goldQuests[_goldQuestSchemaId].reward); //make sure there is gold that can be quested
        require(s.players[_playerId].currentHealth > q.goldQuests[_goldQuestSchemaId].damage, "not enough hp"); //hp check// add require for health check
        require(s.players[_playerId].level >= q.goldQuests[_goldQuestSchemaId].level, "not high enough level"); //hp check// add require for health check
        q.goldQuestStart[_goldQuestSchemaId][_playerId] = block.timestamp; //set timer for quest
        s.players[_playerId].status = 2;//change status
        q.currentQuest[_playerId] = _goldQuestSchemaId;
    }


    // function _startQuestGold(uint256 _tokenId) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     QuestStorage storage q = diamondStorageQuest();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_tokenId].status == 0); //make sure player is idle
    //     require(s.owners[_tokenId] == msg.sender); //ownerOf
    //     require(c.goldCount <= 10000000); // less than one 10M
    //     c.goldCount++;
    //     s.players[_tokenId].status = 2; //set quest status
    //     q.goldQuest[_tokenId] = block.timestamp; //set start time
    // }

    function _endQuestGold(uint256 _playerId, uint256 _goldQuestSchemaId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        QuestStorage storage q = diamondStorageQuest();
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //onlyOwner
        require(s.players[_playerId].status == 2, "Dog, you are not gold questing"); //currently gold questing
        require(q.currentQuest[_playerId] == _goldQuestSchemaId, "This is not the right quest"); //currently gold questing
        uint256 timer;
        s.players[_playerId].agility >= q.goldQuests[_goldQuestSchemaId].time ? timer = q.goldQuests[_goldQuestSchemaId].time : timer = q.goldQuests[_goldQuestSchemaId].time + 10 - s.players[_playerId].agility;
        require(block.timestamp >= q.goldQuestStart[_goldQuestSchemaId][_playerId] + timer, "it's too early to pull out");
        s.players[_playerId].status = 0; //set back to idle
        uint256 damage;  
        s.players[_playerId].defense >= q.goldQuests[_goldQuestSchemaId].damage ? damage = 1 : damage = q.goldQuests[_goldQuestSchemaId].damage - s.players[_playerId].defense;
        s.players[_playerId].currentHealth -= damage;
        q.currentQuest[_playerId] = 0;
        delete q.goldQuest[_playerId]; //remove the start time (need to test this, why not just set to 0)
        c.goldBalance[msg.sender] += q.goldQuests[_goldQuestSchemaId].reward; //mint reward
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        c.goldBalance[feeRecipient] -= q.goldQuests[_goldQuestSchemaId].reward;
        q.goldQuests[_goldQuestSchemaId].maxReward -= q.goldQuests[_goldQuestSchemaId].reward;
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

    function _getGoldQuestCount() internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.goldQuestCounter;
    }

    function _getGoldQuest(uint256 _goldQuestId) internal view returns (GoldQuestSchema memory) {
        QuestStorage storage q = diamondStorageQuest();
        return q.goldQuests[_goldQuestId];

    }

    function _getGoldBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.goldBalance[_address];
    }

    function _getGemBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.gemBalance[_address];
    }

    function _getGoldStart(uint256 _goldQuestId, uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
       return q.goldQuestStart[_goldQuestId][_playerId];
    }

    function _getGemStart(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.gemQuest[_playerId];
    }

    function _getCooldown(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.cooldowns[_playerId];
    }


    // function getGold() internal {
    //     CoinStorage storage c = diamondStorageCoin();
    //     c.goldBalance[msg.sender] += 100;
    // }

    // function _feeMintTest(uint256 _amount) internal {
    //     CoinStorage storage c = diamondStorageCoin();
    //     address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
    //     c.goldBalance[feeRecipient] += _amount;
    // }
}

contract QuestFacet {
    event BeginQuesting(address indexed _playerAddress, uint256 _id);
    event CreateGoldQuest(uint256 _goldQuestId, GoldQuestSchema _goldQuest);
    event BeginGoldQuest(address indexed _playerAddress, uint256 indexed _playerId, uint256 indexed _goldQuestScheme);
    event EndGoldQuest(address indexed _playerAddress, uint256 indexed _playerId, uint256 indexed _goldQuestScheme);

    function createQuestGold(uint256 _reward, uint256 _maxReward, uint256 _level, uint256 _damage, uint256 _time) external {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        StorageLib._createGoldQuest(_reward, _maxReward, _level, _damage, _time);
        uint256 id = StorageLib._getGoldQuestCount();
        emit CreateGoldQuest(id, getGoldQuest(id));

    }

    function startQuestGold(uint256 _playerId, uint256 _goldQuestSchemaId) external {
        StorageLib._startQuestGold(_playerId, _goldQuestSchemaId);
        emit BeginGoldQuest(msg.sender, _playerId, _goldQuestSchemaId);
    }

    function endQuestGold(uint256 _playerId, uint256 _goldQuestSchemaId) external {
        StorageLib._endQuestGold(_playerId, _goldQuestSchemaId);
        emit EndGoldQuest(msg.sender, _playerId, _goldQuestSchemaId);
    }

    function startQuestGem(uint256 _tokenId) external {
        StorageLib._startQuestGem(_tokenId);
        emit BeginQuesting(msg.sender, _tokenId);
    }

    function endQuestGem(uint256 _tokenId) external {
        StorageLib._endQuestGem(_tokenId);
        // emit EndQuesting(msg.sender, _tokenId);
    }

    function getGoldQuestCount() public view returns (uint256){
        return StorageLib._getGoldQuestCount();
    }

    function getGoldQuest(uint256 _goldQuestId) public view returns (GoldQuestSchema memory) {
        return StorageLib._getGoldQuest(_goldQuestId);
    }

    function getGemBalance(address _address) public view returns (uint256) {
        return StorageLib._getGemBalance(_address);
    }

    function getGoldStart(uint256 _goldQuestId, uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGoldStart(_goldQuestId, _playerId);
    }

    function getGemStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGemStart(_playerId);
    }

    function getCooldown(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getCooldown(_playerId);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}