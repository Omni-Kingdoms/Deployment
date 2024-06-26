// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import "../utils/Strings.sol";
import "../utils/Base64.sol";
import "../ERC721Storage.sol";
import "../interfaces/IGateway.sol";

/// @title Player Storage Library
/// @dev Library for managing storage of player data
library PlayerStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant TRANSFER_STORAGE_POSITION = keccak256("transfer.test.storage.a");

    using PlayerSlotLib for PlayerSlotLib.Player;
    using PlayerSlotLib for PlayerSlotLib.Slot;
    using PlayerSlotLib for PlayerSlotLib.TokenTypes;

    /// @dev Struct defining player storage
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

    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // function _deletePlayer(address _sender, uint256 _playerId) internal {
    //     PlayerStorage storage s = diamondStorage();
    //     require(s.owners[_playerId] == _sender);
    //     require(_playerId <= s.playerCount, "Player does not exist");

    //     // Reset Player data - TODO
    //     // PlayerSlotLib.Player storage playerToDelete = s.players[_playerId];
    //     // playerToDelete = PlayerSlotLib.Player({/*...initialize with default values...*/});

    //     // Reset owner data
    //     s.owners[_playerId] = address(0);

    //     // Reduce the balance of the player's owner
    //     s.balances[s.owners[_playerId]] = 0;

    //     // Clear allowances
    //     s.allowances[s.owners[_playerId]][address(this)] = 0;

    //     // Decrement playerCount
    //     s.playerCount--;

    //     // Remove player from the addressToPlayers mapping
    //     uint256[] storage playerIds = s.addressToPlayers[s.owners[_playerId]];
    //     for (uint256 i = 0; i < playerIds.length; i++) {
    //         if (playerIds[i] == _playerId) {
    //             playerIds[i] = playerIds[playerIds.length - 1];
    //             playerIds.pop();
    //             break;
    //         }
    //     }

    //     // Delete player's slot
    //     delete s.slots[_playerId];
    // }

    /// @notice Mints a new player
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function _mint(string memory _name, bool _isMale, uint256 _class, address _to) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.playerCount <= 8000);
        require(!s.usedNames[_name], "name is taken");
        require(_class <= 2);
        require(bytes(_name).length <= 10);
        require(bytes(_name).length >= 3);
        s.playerCount++;
        string memory uri;
        if (_class == 0) {
            //warrior
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmV5pSsMGGMLW3Y9yQ8qSLSMDQakdnjhjS4k5he6mJyPeH"
                : uri = "https://ipfs.io/ipfs/QmfBNHpxpwUNgtw6iXBxKXLbVxom8mpdBsgqZZy59pRM5C";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1, //level
                0, //xp
                0, //status
                11, //strength
                12, //health
                12, //currentHealth
                10, //magic
                10, //mana
                10, //maxMana
                10, //agility
                1,
                1,
                1,
                1,
                11, //defense
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                _class
            );
        } else if (_class == 1) {
            //assasin
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmQXeYe9rxRkkqfEB7DrZRSG2S1yrNgj64V8m6v7KetzQd"
                : uri = "https://ipfs.io/ipfs/QmUqZKRudnang1GXbD2nHHwmJfNNBFQVdmoH8WAneaii5h";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1, //level
                0, //xp
                0, //status
                11, //strength
                11, //health
                11, //currentHealth
                10, //magic
                10, //mana
                10, //maxMana
                12, //agility
                1,
                1,
                1,
                1,
                10, //defense
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                _class
            );
        } else if (_class == 2) {
            //mage
            _isMale
                ? uri = "https://ipfs.io/ipfs/QmUbWxUd8sX4MZojKERUPmPu9YtAYfYroBS4Te1HJEKucy"
                : uri = "https://ipfs.io/ipfs/QmbVABt9sKpNUa8DgMJde3DBCQyorSCT9V1Dzd6cJ8ZUmP";
            s.players[s.playerCount] = PlayerSlotLib.Player(
                1, //level
                0, //xp
                0, //status
                10, //strength
                10, //health
                10, //currentHealth
                12, //magic
                12, //mana
                12, //maxMana
                10, //agility
                1,
                1,
                1,
                1,
                10, //defense
                _name,
                uri,
                _isMale,
                PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
                _class
            );
        }
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.usedNames[_name] = true;
        s.owners[s.playerCount] = _to;
        s.addressToPlayers[_to].push(s.playerCount);
        s.balances[_to]++;
    }

    function _playerCount() internal view returns (uint256) {
        PlayerStorage storage s = diamondStorage();
        return s.playerCount;
    }

    function _nameAvailable(string memory _name) internal view returns (bool) {
        PlayerStorage storage s = diamondStorage();
        return s.usedNames[_name];
    }

    /// @notice Changes the name of a player
    /// @param _id The id of the player
    /// @param _newName The new name of the player
    function _changeName(uint256 _id, string memory _newName) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_id] == msg.sender);
        require(!s.usedNames[_newName], "name is taken");
        require(bytes(_newName).length > 3, "Cannot pass an empty hash");
        require(bytes(_newName).length < 10, "Cannot be longer than 10 chars");
        string memory existingName = s.players[_id].name;
        if (bytes(existingName).length > 0) {
            delete s.usedNames[existingName];
        }
        s.players[_id].name = _newName;
        s.usedNames[_newName] = true;
    }

    function _getPlayer(uint256 _id) internal view returns (PlayerSlotLib.Player memory player) {
        PlayerStorage storage s = diamondStorage();
        player = s.players[_id];
    }

    function _ownerOf(uint256 _id) internal view returns (address owner) {
        PlayerStorage storage s = diamondStorage();
        owner = s.owners[_id];
    }

    /// @notice Transfer the player to someone else
    /// @param _to Address of the account where the caller wants to transfer the player
    /// @param _id ID of the player to transfer
    function _transfer(address _to, uint256 _id) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_id] == msg.sender);
        require(_to != address(0), "_to cannot be zero address");
        s.owners[_id] = _to;

        //Note - storing this in a memory variable to save gas
        uint256 balances = s.balances[msg.sender];
        for (uint256 i = 0; i < balances; i++) {
            if (s.addressToPlayers[msg.sender][i] == _id) {
                delete s.addressToPlayers[msg.sender][i];
                break;
            }
        }
        s.balances[msg.sender]--;
        s.balances[_to]++;
    }

    function _getPlayers(address _address) internal view returns (uint256[] memory) {
        PlayerStorage storage s = diamondStorage();
        return s.addressToPlayers[_address];
    }

    function _levelUp(uint256 _playerId, uint256 _stat) internal {
        PlayerStorage storage s = diamondStorage();
        PlayerSlotLib.Player memory player = s.players[_playerId];
        require(player.xp >= player.level * 10); //require the player has enough xp to level up, at least 10 times their level
        if (_stat == 0) {
            //if strength
            s.players[_playerId].strength++;
        } else if (_stat == 1) {
            //if health
            s.players[_playerId].health++;
        } else if (_stat == 2) {
            //if agility
            s.players[_playerId].agility++;
        } else if (_stat == 3) {
            //if magic
            s.players[_playerId].magic++;
        } else if (_stat == 4) {
            //if defense
            s.players[_playerId].defense++;
        } else if (_stat == 5) {
            // if luck
            s.players[_playerId].luck++;
        } else {
            // must be mana
            s.players[_playerId].maxMana++;
            s.players[_playerId].mana = s.players[_playerId].maxMana;
        }
        s.players[_playerId].currentHealth = s.players[_playerId].health; //restore health to full
        s.players[_playerId].xp = player.xp - (player.level * 10); //subtract xp form the player
        s.players[_playerId].level++; //level up the player
    }
}

/// @title Player Facet
/// @dev Contract managing interaction with player data
contract PlayerFacet is ERC721FacetInternal {
    // contract PlayerFacet {
    using Strings for uint256;

    event Mint(uint256 indexed id, address indexed owner, string name, uint256 _class);
    event NameChange(address indexed owner, uint256 indexed id, string indexed newName);
    event LevelUp(uint256 indexed _playerId, uint256 indexed _stat);

    function playerCount() public view returns (uint256) {
        return PlayerStorageLib._playerCount();
    }

    /// @notice Mints a new player
    /// @dev Emits a Mint event
    /// @dev Calls the _mint function from the PlayerStorageLib
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function mint(string memory _name, bool _isMale, uint256 _class, address _to) external payable {
        uint256 cost = 16000000000000000;
        require(msg.value >= cost);
        address payable feeAccount = payable(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        //feeAccount.call{value: cost};
        (bool sent, bytes memory data) = feeAccount.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        PlayerStorageLib._mint(_name, _isMale, _class, _to);
        uint256 count = playerCount();
        emit Mint(count, _to, _name, _class);

        //TODO - somehow
        _safeMint(_to, count);
    }

    /// @notice Changes the name of a player
    /// @dev Emits a NameChange event
    /// @param _id The id of the player
    /// @param _newName The new name of the player
    function changeName(uint256 _id, string memory _newName) external {
        PlayerStorageLib._changeName(_id, _newName);
        emit NameChange(msg.sender, _id, _newName);
    }

    /// @notice Retrieves a player
    /// @param _playerId The id of the player
    /// @return player The player data
    function getPlayer(uint256 _playerId) external view returns (PlayerSlotLib.Player memory player) {
        player = PlayerStorageLib._getPlayer(_playerId);
    }

    function nameAvailable(string memory _name) external view returns (bool available) {
        available = PlayerStorageLib._nameAvailable(_name);
    }

    function ownerOfPlayer(uint256 _playerId) external view returns (address owner) {
        owner = PlayerStorageLib._ownerOf(_playerId);
    }

    /// @notice Retrieves the players owned by an address
    /// @param _address The owner address
    /// @return An array of player ids
    function getPlayers(address _address) external view returns (uint256[] memory) {
        return PlayerStorageLib._getPlayers(_address);
    }

    /// @notice Retrieves the current block timestamp
    /// @return The current block timestamp
    function getBlocktime() external view returns (uint256) {
        return (block.timestamp);
    }

    function levelUp(uint256 _playerId, uint256 _stat) external {
        PlayerStorageLib._levelUp(_playerId, _stat);
        emit LevelUp(_playerId, _stat);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
