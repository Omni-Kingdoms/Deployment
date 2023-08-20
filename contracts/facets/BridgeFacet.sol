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
}

struct ChainData {
    uint256 chainId;
    string name;
    address portal;
    address diamond;
}

/// @title Player Storage Library
/// @dev Library for managing storage of player data
library BridgeStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant BRIDGE_STORAGE_POSITION = keccak256("bridge.test.storage.a");

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
        mapping(uint256 => bool) origin;
        mapping(uint256 => uint256) playerToBaseChain;
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

    function _bridgePlayer(uint256 _playerId) internal returns (BridgeFormat memory) {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge(); 
        require(s.players[_playerId].status == 0, "you are not idle"); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
        s.players[_playerId].status = 100; //set status to bridging 
        PlayerSlotLib.Player storage player = s.players[_playerId];
        uint256 baseChain;
        uint256 baseId;
        if (!br.origin[_playerId]) { //have not bridged before
            baseChain = block.chainid; // set origin chain to this chain
            baseId = _playerId;
            br.origin[_playerId] = true;
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
            player.name, 
            player.male
        );
        return bridgeFormat;
    }


    function _remintPlayer(BridgeFormat memory _format) internal {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge();
        uint256 _playerId;
        if (br.chainToPlayerId[_format.baseChain][_format.baseId] > 0) { //if they have been here before
            _playerId = br.chainToPlayerId[_format.baseChain][_format.baseId];
            s.players[_playerId].status = 0; //unfreeze player
            s.players[_playerId].level = _format.level; 
            s.players[_playerId].xp = _format.xp; 
            s.players[_playerId].strength = _format.strength; 
            s.players[_playerId].health = _format.health; 
            s.players[_playerId].magic = _format.magic; 
            s.players[_playerId].maxMana = _format.maxMana; 
            s.players[_playerId].agility = _format.agility; 
        } else { //have not been here before
            _birdgeMint(_format);
        }   
    }

    function _birdgeMint(BridgeFormat memory _format) internal {
        PlayerStorage storage s = diamondStorage();
        BridgeStorage storage br = diamondStorageBridge();
        s.playerCount++; //increment playerCount

        string memory _name = string(
            abi.encodePacked(_format.name, Strings.toString(s.playerCount))
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
        s.owners[s.playerCount] = msg.sender;
        s.addressToPlayers[msg.sender].push(s.playerCount);
        s.balances[msg.sender]++;
    }










    function _createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) internal {
        BridgeStorage storage br = diamondStorageBridge();
        br.chainData[_chainId] = ChainData(_chainId, _name, _portal, _diamond);
    }

    function _getChainData(uint256 _chainId) internal view returns (ChainData memory) {
        BridgeStorage storage br = diamondStorageBridge();
        return br.chainData[_chainId];
    }

}



contract BridgeFacet is ERC721FacetInternal {

    event BridgeCreated(uint256 indexed _chainId, address indexed _portal, address indexed _diamond);
    event BridgePlayer(uint256 indexed _playerId, BridgeFormat _format);
    event ReMintPlayer(BridgeFormat _format);

    IOmniPortal public omni;

    function reMintPlayer(BridgeFormat memory _format) public {
        
    }


    function bridgePlayer(uint256 _playerId, uint256 _chainId) public {
        ChainData memory chainData = getChainData(_chainId);
        //omni = IOmniPortal(0xc0400275F85B45DFd2Cfc838dA8Ee4214B659e25);
        omni = IOmniPortal(chainData.portal);
        BridgeFormat memory bridgeFormat = BridgeStorageLib._bridgePlayer(_playerId);
        omni.sendXChainTx(
            chainData.name, // destination rollup
            chainData.diamond, // contract on destination rollup
            0, // msg.value
            100_000, // gas limit
            abi.encodeWithSignature("reMintPlayer((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,string,bool))", bridgeFormat)
        );
        emit BridgePlayer(_playerId, bridgeFormat);
    }

    function createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) public {
        BridgeStorageLib._createBridge(_chainId, _name, _portal, _diamond);
        emit BridgeCreated(_chainId, _portal, _diamond);
    }

    function getChainData(uint256 _chainId) public view returns(ChainData memory) {
        return BridgeStorageLib._getChainData(_chainId);
    }

}