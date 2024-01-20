// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

// StatusCodes {
//     0: idle;
//     1: healthTrain;
//     2: goldQuest;
//     3: manaTrain;
//     4: Arena;
//     5: gemQuest;
//     99: exchange
// }

library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant TRAIN_STORAGE_POSITION = keccak256("train.test.storage.a");

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

    struct TrainStorage {
        mapping(uint256 => uint256) basicHealth;
        mapping(uint256 => uint256) basicMana;
        mapping(uint256 => uint256) meditation;
        mapping(uint256 => uint256) education;
        mapping(uint256 => uint256) cooldown;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTrain() internal pure returns (TrainStorage storage ds) {
        bytes32 position = TRAIN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _startTrainingBasicHealth(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_playerId].status == 0); //is idle
        require(s.owners[_playerId] == msg.sender); // ownerOf
        require(s.players[_playerId].health > s.players[_playerId].currentHealth); //make sure player isnt at full health
        s.players[_playerId].status = 1; //set status to trainHealth
        t.basicHealth[_playerId] = block.timestamp;
        delete t.cooldown[_playerId];
    }

    function _endTrainingBasicHealth(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.owners[_playerId] == msg.sender);
        //require(tx.origin == msg.sender);
        require(s.players[_playerId].status == 1); //check that they are doing basic health
        uint256 timer;
        s.players[_playerId].agility >= 20 ? timer = 10 : timer = 30 - s.players[_playerId].agility;
        require(block.timestamp >= t.basicHealth[_playerId] + timer, "it's too early to pull out");
        s.players[_playerId].status = 0; //reset status back to idle
        delete t.basicHealth[_playerId];
        if (s.players[_playerId].health - s.players[_playerId].currentHealth >= 3) {
            s.players[_playerId].currentHealth += 3;
        } else {
            s.players[_playerId].health = s.players[_playerId].currentHealth;
        }
    }

    function _startTrainingMana(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_tokenId].status == 0); //is idle
        require(s.owners[_tokenId] == msg.sender); // ownerOf
        require(block.timestamp >= t.cooldown[_tokenId] + 1); //check time requirement

        s.players[_tokenId].status = 3; //mana training
        t.basicMana[_tokenId] = block.timestamp;
        delete t.cooldown[_tokenId];
    }

    function _endTrainingMana(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.owners[_playerId] == msg.sender);
        require(s.players[_playerId].status == 3); //require that they are training mana
        require(block.timestamp >= t.basicMana[_playerId] + 300, "it's too early to pull out");
        s.players[_playerId].status = 0;
        delete t.basicMana[_playerId];
        t.cooldown[_playerId] = block.timestamp; //reset the cool down
        require(s.players[_playerId].mana < s.players[_playerId].maxMana);
        s.players[_playerId].mana++;
    }

    function _startMeditation(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_tokenId].status == 0); //is idle
        require(s.owners[_tokenId] == msg.sender); // ownerOf

        s.players[_tokenId].status = 1; //set status to training
        t.meditation[_tokenId] = block.timestamp;
        delete t.cooldown[_tokenId];
    }

    function _getHealthStart(uint256 _playerId) internal view returns (uint256) {
        TrainStorage storage t = diamondStorageTrain();
        return t.basicHealth[_playerId];
    }

    function _getManaStart(uint256 _playerId) internal view returns (uint256) {
        TrainStorage storage t = diamondStorageTrain();
        return t.basicMana[_playerId];
    }

    function _adminMaxHealth(uint256 _playerId, uint256 _newHealth) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        s.players[_playerId].health = _newHealth; //resetMaxHealth
        s.players[_playerId].currentHealth = _newHealth; //reset currentHealth to full
    }
}

contract TrainFacet {
    event BeginTrainingBasicHealth(address indexed _playerAddress, uint256 indexed _id);
    event EndTrainingBasicHealth(address indexed _playerAddress, uint256 indexed _id);
    event BeginTrainingMana(address indexed _playerAddress, uint256 indexed _id);
    event EndTrainingMana(address indexed _playerAddress, uint256 indexed _id);

    function startTrainingBasicHealth(uint256 _playerId) external {
        StorageLib._startTrainingBasicHealth(_playerId);
        emit BeginTrainingBasicHealth(msg.sender, _playerId);
    }

    function endTrainingBasicHealth(uint256 _playerId) external {
        StorageLib._endTrainingBasicHealth(_playerId);
        emit EndTrainingBasicHealth(msg.sender, _playerId);
    }

    function startTrainingMana(uint256 _tokenId) external {
        StorageLib._startTrainingMana(_tokenId);
        emit BeginTrainingMana(msg.sender, _tokenId);
    }

    function endTrainingMana(uint256 _tokenId) external {
        StorageLib._endTrainingMana(_tokenId);
        emit EndTrainingMana(msg.sender, _tokenId);
    }

    function getHealthStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getHealthStart(_playerId);
    }

    function getManaStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getManaStart(_playerId);
    }

    ///////////////////////// admin //////////////////////

    // function _adminMaxHealth(uint256 _playerId, uint256 _newHealth) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     s.players[_playerId].health = _newHealth; //resetMaxHealth
    //     s.players[_playerId].currentHealth = _newHealth; //reset currentHealth to full
    // }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
