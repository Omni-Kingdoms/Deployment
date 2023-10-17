// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import "../utils/Strings.sol";
import "../utils/Base64.sol";
import "../ERC721Storage.sol";
import "../interfaces/IGateway.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


struct PlayerDrop {
    uint256 id;
    uint256 price;
    bytes32 merkleRoot;
    string name;
}

/// @title Player Storage Library
/// @dev Library for managing storage of player data
library PlayerDropStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant PLAYER_DROP_STORAGE_POSITION = keccak256("playerDrop.test.storage.a");

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

    struct PlayerDropStorage {
        uint256 playerDropCount;
        mapping(uint256 => PlayerDrop) playerDrops;
        mapping(uint256 => mapping(address => bool)) claimed;
        mapping(address => uint256[]) addressToDrops; 
    }

    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStoragePlayerDrop() internal pure returns (PlayerDropStorage storage ds) {
        bytes32 position = PLAYER_DROP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Mints a new player
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function _mint(string memory _name, bool _isMale, uint256 _class) internal {
        PlayerStorage storage s = diamondStorage();
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
        s.owners[s.playerCount] = msg.sender;
        s.addressToPlayers[msg.sender].push(s.playerCount);
        s.balances[msg.sender]++;
    }

   function _mintPaladin(string memory _name, bool _isMale) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_name], "name is taken");
        require(bytes(_name).length <= 10);
        require(bytes(_name).length >= 3);
        s.playerCount++;
        string memory uri;
        _isMale
            ? uri = "https://ipfs.io/ipfs/QmWQQL6N9Afcq2pdbGvja1TViiCWk4k6vB5VMC9tcMKce9"
            : uri = "https://ipfs.io/ipfs/QmRidJfgfR6V9LBvYA6RKojDPykq5G2zLnNAxArLMUMnCd";
        s.players[s.playerCount] = PlayerSlotLib.Player(
            1, //level
            0, //xp 
            0, //status
            13, //strength
            13, //health
            13, //currentHealth
            13, //magic
            13, //mana
            13, //maxMana
            13, //agility
            1,
            1,
            1,
            1,
            13, //defense
            _name,
            uri,
            _isMale,
            PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
            3
        ); 
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.usedNames[_name] = true;
        s.owners[s.playerCount] = msg.sender;
        s.addressToPlayers[msg.sender].push(s.playerCount);
        s.balances[msg.sender]++; 
   } 


   function _claimPlayerDrop(uint256 _playerDropId, bytes32[] calldata _proof, string memory _name, bool _isMale, uint256 _class) internal {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        require(!pd.claimed[_playerDropId][msg.sender], "Address has already claimed the drop"); //check to see if they have already claimed;
        require(MerkleProof.verify(_proof, pd.playerDrops[_playerDropId].merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle proof"); //check to see if sender is whitelisted
        require(msg.value >= pd.playerDrops[_playerDropId].price);
        pd.claimed[_playerDropId][msg.sender] = true; //set claim status to true
        _mint(_name, _isMale, _class);
    }

   function _claimPlayerDropPaladin(uint256 _playerDropId, bytes32[] calldata _proof, string memory _name, bool _isMale) internal {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        require(!pd.claimed[_playerDropId][msg.sender], "Address has already claimed the drop"); //check to see if they have already claimed;
        require(MerkleProof.verify(_proof, pd.playerDrops[_playerDropId].merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle proof"); //check to see if sender is whitelisted
        require(msg.value >= pd.playerDrops[_playerDropId].price);
        require(keccak256(abi.encodePacked(pd.playerDrops[_playerDropId].name)) == keccak256(abi.encodePacked('Scroll')));
        pd.claimed[_playerDropId][msg.sender] = true; //set claim status to true
        _mintPaladin(_name, _isMale);
    }

    function _createPlayerDrop(bytes32 _merkleRoot, string memory _name, uint256 _price) internal {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        pd.playerDropCount++; //increment the drop counter
        pd.playerDrops[pd.playerDropCount] = PlayerDrop(pd.playerDropCount, _price, _merkleRoot, _name); //create drop struct
    }

    function _verifyPlayerDropWhitelist(bytes32[] calldata _proof, uint256 _playerDropId, address _address) internal view returns (bool) {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, pd.playerDrops[_playerDropId].merkleRoot, leaf);
    }

    function _claimedStatus(uint256 _playerDropId, address _address) internal view returns (bool) {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        return pd.claimed[_playerDropId][_address];
    }

    function _getPlayerDropMerkleRoot(uint256 _playerDropId) internal view returns (bytes32) {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        return pd.playerDrops[_playerDropId].merkleRoot;
    }

    function _getPlayerDrop(uint256 _playerDropId) internal view returns (PlayerDrop memory) {
        PlayerDropStorage storage pd = diamondStoragePlayerDrop();
        return pd.playerDrops[_playerDropId];
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

    function _playerCount() internal view returns (uint256) {
        PlayerStorage storage s = diamondStorage();
        return s.playerCount;
    }

}

/// @title Player Facet
/// @dev Contract managing interaction with player data
contract PlayerDropFacet is ERC721FacetInternal {
    // contract PlayerFacet {
    using Strings for uint256;

    event Mint(uint256 indexed id, address indexed owner, string name, uint256 _class);
    event NameChange(address indexed owner, uint256 indexed id, string indexed newName);
    event ClaimPlayer(uint256 indexed _playerDropId);


    function createPlayerDrop(bytes32 _merkleRoot, string memory _name, uint256 _price) external {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        PlayerDropStorageLib._createPlayerDrop(_merkleRoot, _name, _price);
    }

    function claimPlayerDrop(uint256 _playerDropId, bytes32[] calldata _proof, string memory _name, bool _isMale, uint256 _class) external payable {
        require(msg.value >= getPlayerDrop(_playerDropId).price);
        address payable feeAccount = payable(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        //feeAccount.call{value: getPlayerDrop(_playerDropId).price};
        (bool sent, bytes memory data) = feeAccount.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        PlayerDropStorageLib._claimPlayerDrop(_playerDropId, _proof, _name, _isMale, _class);
        emit ClaimPlayer(_playerDropId);
        uint256 count = PlayerDropStorageLib._playerCount();
        _safeMint(msg.sender, count);
    }

    function verifyPlayerDropWhitelist(bytes32[] calldata _proof, uint256 _playerDropId, address _address) public view returns(bool) {
        return PlayerDropStorageLib._verifyPlayerDropWhitelist(_proof, _playerDropId, _address);
    }

    function claimedStatus(uint256 _playerDropId, address _address) public view returns (bool) {
        return PlayerDropStorageLib._claimedStatus(_playerDropId, _address);
    }

    function getPlayerDropMerkleRoot(uint256 _playerDropId) external view returns (bytes32) {
        return PlayerDropStorageLib._getPlayerDropMerkleRoot(_playerDropId);
    }

    function changeNameFee(uint256 _id, string memory _newName) external payable {
        PlayerDropStorageLib._changeName(_id, _newName);
        require(msg.value >= 10);
        emit NameChange(msg.sender, _id, _newName);
    }

    function getPlayerDrop(uint256 _playerDropId) public view returns (PlayerDrop memory) {
        return PlayerDropStorageLib._getPlayerDrop(_playerDropId);
    }

    function claimPlayerDropPaladin(uint256 _playerDropId, bytes32[] calldata _proof, string memory _name, bool _isMale) public payable {
        require(msg.value >= getPlayerDrop(_playerDropId).price);
        address payable feeAccount = payable(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        //feeAccount.call{value: getPlayerDrop(_playerDropId).price};
        (bool sent, bytes memory data) = feeAccount.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        PlayerDropStorageLib._claimPlayerDropPaladin(_playerDropId, _proof, _name, _isMale);
        emit ClaimPlayer(_playerDropId);
        uint256 count = PlayerDropStorageLib._playerCount();
        _safeMint(msg.sender, count);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
