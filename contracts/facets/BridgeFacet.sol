// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IOmniPortal} from "@omni/contracts/contracts/interfaces/IOmniPortal.sol";

import "../libraries/PlayerSlotLib.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import "../utils/Strings.sol";
import "../utils/Base64.sol";
import "../ERC721Storage.sol";
import "../interfaces/IGateway.sol";


struct BridgeFormat {
    uint256 class;
    uint256 level;
    uint256 xp;
    uint256 strength;
    uint256 health;
    uint256 magic;
    uint256 maxMana;
    uint256 agility;
    uint256 defense;
    uint256 baseChain;
    uint256 baseId;
    string name;
    bool isMale;
    address sender;
}

struct ChainData {
    uint256 chainId;
    string name;
    address portal;
    address diamond;
}

struct BridgegeCoinFormat {
    address sender;
    uint256 amount;
}

/// @title Player Storage Library
/// @dev Library for managing storage of player data
library BridgeStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant BRIDGE_STORAGE_POSITION = keccak256("bridge.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");

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

    struct BridgeStorage {
        mapping(uint256 => ChainData) chainData;
        mapping(uint256 => mapping(uint256 => uint256)) chainToPlayerId;
        mapping(uint256 => mapping(uint256 => string)) chainToPlayerName;
        mapping(uint256 => bool) bridged;
        mapping(uint256 => uint256) playerToBaseChain;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }


    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageBridge() internal pure returns (BridgeStorage storage ds) {
        bytes32 position = BRIDGE_STORAGE_POSITION;
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

    function _bridgePlayer(uint256 _playerId) internal returns (BridgeFormat memory) {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge(); 
        require(s.players[_playerId].status == 0, "you are not idle"); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
        s.players[_playerId].status = 100; //set status to bridging 
        PlayerSlotLib.Player storage player = s.players[_playerId];
        uint256 baseChain;
        uint256 baseId;
        if (!br.bridged[_playerId]) { //have not bridged before
            baseChain = block.chainid; // set origin chain to this chain
            baseId = _playerId;
            br.bridged[_playerId] = true;
            br.chainToPlayerId[baseChain][_playerId] = _playerId;
            br.chainToPlayerName[baseChain][_playerId] = s.players[_playerId].name;
        } else { //have bridged before
            baseChain = br.playerToBaseChain[_playerId];
            baseId = br.chainToPlayerId[baseChain][_playerId];
        }
        BridgeFormat memory bridgeFormat = BridgeFormat(
            player.playerClass,
            player.level,
            player.xp,
            player.strength,
            player.health,
            player.magic,
            player.maxMana,
            player.agility,
            player.defense,
            baseChain, 
            baseId,
            br.chainToPlayerName[baseChain][_playerId], 
            player.male,
            msg.sender
        );
        return bridgeFormat;
    }


    function _remintPlayer(BridgeFormat memory _format) internal {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge();
        uint256 _playerId;
        if (br.chainToPlayerId[_format.baseChain][_format.baseId] > 0) { //if they have been here before
            _playerId = br.chainToPlayerId[_format.baseChain][_format.baseId]; //set the local id
            s.players[_playerId].status = 0; //unfreeze player
            s.players[_playerId].level = _format.level; 
            s.players[_playerId].xp = _format.xp; 
            s.players[_playerId].strength = _format.strength; 
            s.players[_playerId].health = _format.health; 
            s.players[_playerId].currentHealth = _format.health; 
            s.players[_playerId].magic = _format.magic; 
            s.players[_playerId].maxMana = _format.maxMana; 
            s.players[_playerId].mana = _format.maxMana; 
            s.players[_playerId].agility = _format.agility; 
        } else { //have not been here before
            _birdgeMint(_format);
        }   
    }

    function _birdgeMint(BridgeFormat memory _format) internal {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge();
        s.playerCount++; //increment playerCount
        br.chainToPlayerId[_format.baseChain][_format.baseId] = s.playerCount;
        br.chainToPlayerName[_format.baseChain][_format.baseId] = _format.name;
        br.bridged[s.playerCount] = true;
        br.playerToBaseChain[s.playerCount] = _format.baseChain;
        string memory _name = string(
            abi.encodePacked(_format.name,"-", Strings.toString(s.playerCount))
        );
        string memory uri;
        if (_format.class == 0) {
            _format.isMale
                ? uri = "https://ipfs.io/ipfs/QmV5pSsMGGMLW3Y9yQ8qSLSMDQakdnjhjS4k5he6mJyPeH"
                : uri = "https://ipfs.io/ipfs/QmfBNHpxpwUNgtw6iXBxKXLbVxom8mpdBsgqZZy59pRM5C";
        } else if (_format.class == 1) {
            _format.isMale
                ? uri = "https://ipfs.io/ipfs/QmQXeYe9rxRkkqfEB7DrZRSG2S1yrNgj64V8m6v7KetzQd"
                : uri = "https://ipfs.io/ipfs/QmUqZKRudnang1GXbD2nHHwmJfNNBFQVdmoH8WAneaii5h";
        } else if (_format.class == 2) {
            _format.isMale
                ? uri = "https://ipfs.io/ipfs/QmUbWxUd8sX4MZojKERUPmPu9YtAYfYroBS4Te1HJEKucy"
                : uri = "https://ipfs.io/ipfs/QmbVABt9sKpNUa8DgMJde3DBCQyorSCT9V1Dzd6cJ8ZUmP";
        }
        s.players[s.playerCount] = PlayerSlotLib.Player(
            _format.level, //level
            _format.xp, //xp 
            0, //status
            _format.strength, //strength
            _format.health, //health
            _format.health, //currentHealth
            _format.magic, //magic
            _format.maxMana, //mana
            _format.maxMana, //maxMana
            _format.agility, //agility
            1,
            1,
            1,
            1,
            _format.defense, //defense
            _name,
            uri,
            _format.isMale,
            PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
            _format.class
        );
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.owners[s.playerCount] = _format.sender;
        s.addressToPlayers[_format.sender].push(s.playerCount);
        s.balances[_format.sender]++;
    }


    function _createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) internal {
        BridgeStorage storage br = diamondStorageBridge();
        br.chainData[_chainId] = ChainData(_chainId, _name, _portal, _diamond);
    }

    function _getChainData(uint256 _chainId) internal view returns (ChainData memory) {
        BridgeStorage storage br = diamondStorageBridge();
        return br.chainData[_chainId];
    }

    function _playerCount() internal view returns (uint256) {
        PlayerStorage storage s = diamondStorage();
        return s.playerCount;
    }

    function _firstBridge(uint256 _baseChain, uint256 _baseId) internal view returns (bool firstBridged) {
        BridgeStorage storage br = diamondStorageBridge();
        br.chainToPlayerId[_baseChain][_baseId] > 0 ? firstBridged = false : firstBridged = true;
    }

    function _sendGold(address _sender, uint256 _amount) internal {
        CoinStorage storage c = diamondStorageCoin();
        require(c.goldBalance[_sender] >= _amount);
        c.goldBalance[_sender] -= _amount;
    } 

    function _receiveGold(address _sender, uint256 _amount) internal {
        CoinStorage storage c = diamondStorageCoin();
        c.goldBalance[_sender] += _amount;
    }

}



contract BridgeFacet is ERC721FacetInternal {

    event BridgeCreated(uint256 indexed _chainId, address indexed _portal, address indexed _diamond);
    event BridgePlayer(uint256 indexed _playerId, BridgeFormat _format);
    event ReMintPlayer(uint256 indexed _playerId, BridgeFormat _format);
    event SendGold(address indexed _sender, uint256 indexed _amount);
    event ReceiveGold(address indexed _sender, uint256 indexed _amount);

    function reMintPlayer(BridgeFormat memory _format) public {
        BridgeStorageLib._remintPlayer(_format);
        uint256 count = BridgeStorageLib._playerCount();
        // if (BridgeStorageLib._firstBridge(_format.baseChain, _format.baseId)) {
        //     emit ReMintPlayer(count, _format);
        // }
        _safeMint(_format.sender, count);
    }

    function bridgePlayer(uint256 _playerId, uint256 _chainId) public {
        ChainData memory chainData = getChainData(_chainId);
        //omni = IOmniPortal(0xc0400275F85B45DFd2Cfc838dA8Ee4214B659e25);
        IOmniPortal omni;
        omni = IOmniPortal(chainData.portal);
        BridgeFormat memory bridgeFormat = BridgeStorageLib._bridgePlayer(_playerId);
        omni.sendXChainTx(
            chainData.name, // destination rollup
            chainData.diamond, // contract on destination rollup
            0, // msg.value
            100_000, // gas limit
            abi.encodeWithSignature("reMintPlayer((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,string,bool,address))", bridgeFormat)
        );
        emit BridgePlayer(_playerId, bridgeFormat);
    }

    function bridgePlayerTest(uint256 _playerId, string memory _chain, address _contract) public {
        //ChainData memory chainData = getChainData(_chainId);
        IOmniPortal omni;
        omni = IOmniPortal(0x1B2c14b235e928B42EDE9D83c8143fC9ec309742);
        //omni = IOmniPortal(chainData.portal);
        BridgeFormat memory bridgeFormat = BridgeStorageLib._bridgePlayer(_playerId);
        omni.sendXChainTx(
            _chain, // destination rollup
            _contract, // contract on destination rollup
            0, // msg.value
            100_000, // gas limit
            abi.encodeWithSignature("reMintPlayer((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,string,bool,address))", bridgeFormat)
        );
        emit BridgePlayer(_playerId, bridgeFormat);
    }

    function bridgeGold(string memory _chain, address _contract, uint256 _amount) public {
        //ChainData memory chainData = getChainData(_chainId);
        IOmniPortal omni;
        omni = IOmniPortal(0x1B2c14b235e928B42EDE9D83c8143fC9ec309742);
        //omni = IOmniPortal(chainData.portal);
        BridgegeCoinFormat memory bridgegeCoinFormat = BridgegeCoinFormat(msg.sender, _amount);
        omni.sendXChainTx(
            _chain, // destination rollup
            _contract, // contract on destination rollup
            0, // msg.value
            100_000, // gas limit
            abi.encodeWithSignature("receiveGold((address,uint256))", bridgegeCoinFormat)
        );
        BridgeStorageLib._sendGold(msg.sender, _amount);
        emit SendGold(msg.sender, _amount);
    }

    function receiveGold(BridgegeCoinFormat memory _format) public {
        BridgeStorageLib._receiveGold(_format.sender, _format.amount);
        emit ReceiveGold(_format.sender, _format.amount);
    }


    function createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) public {
        BridgeStorageLib._createBridge(_chainId, _name, _portal, _diamond);
        emit BridgeCreated(_chainId, _portal, _diamond);
    }

    function getChainData(uint256 _chainId) public view returns(ChainData memory) {
        return BridgeStorageLib._getChainData(_chainId);
    }

}