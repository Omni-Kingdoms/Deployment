// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8;

// import {IOmniPortal} from "@omni/contracts/contracts/interfaces/IOmniPortal.sol";

// import "../libraries/PlayerSlotLib.sol";
// import {ERC721Facet} from "./ERC721Facet.sol";
// import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
// import "../utils/Strings.sol";
// import "../utils/Base64.sol";
// import "../ERC721Storage.sol";
// import "../interfaces/IGateway.sol";


// struct BridgeFormat {
//     uint256 class;
//     uint256 level;
//     uint256 xp;
//     uint256 strength;
//     uint256 health;
//     uint256 magic;
//     uint256 maxMana;
//     uint256 agility;
//     uint256 baseChain;
//     uint256 baseId;
//     string name;
//     bool isMale;
// }

// struct ChainData {
//     uint256 chainId;
//     string name;
//     address portal;
//     address diamond;
// }

// /// @title Player Storage Library
// /// @dev Library for managing storage of player data
// library BridgeStorageLib {
//     bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("player.test.storage.a");
//     bytes32 constant BRIDGE_STORAGE_POSITION = keccak256("bridge.test.storage.a");

//     using PlayerSlotLib for PlayerSlotLib.Player;
//     using PlayerSlotLib for PlayerSlotLib.Slot;
//     using PlayerSlotLib for PlayerSlotLib.TokenTypes;

//     /// @dev Struct defining player storage
//     struct PlayerStorage {
//         uint256 totalSupply;
//         uint256 playerCount;
//         mapping(uint256 => address) owners;
//         mapping(uint256 => PlayerSlotLib.Player) players;
//         mapping(address => uint256) balances;
//         mapping(address => mapping(address => uint256)) allowances;
//         mapping(string => bool) usedNames;
//         mapping(address => uint256[]) addressToPlayers;
//         mapping(uint256 => PlayerSlotLib.Slot) slots;
//     }

//     struct BridgeStorage {
//         mapping(uint256 => ChainData) chainData;
//         mapping(uint256 => mapping(uint256 => uint256)) chainToPlayerId;
//         mapping(uint256 => bool) origin;
//         mapping(uint256 => uint256) playerToBaseChain;
//     }


//     /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
//     function diamondStorage() internal pure returns (PlayerStorage storage ds) {
//         bytes32 position = DIAMOND_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }

//     function diamondStorageBridge() internal pure returns (BridgeStorage storage ds) {
//         bytes32 position = BRIDGE_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }

//     function _bridgePlayer(uint256 _playerId, uint256 _chainId) internal returns (BridgeFormat memory) {
//         PlayerStorage storage s = diamondStorage();
//         BridgeStorage storage br = diamondStorageBridge(); 
//         require(s.players[_playerId].status == 0, "you are not idle"); //make sure player is idle
//         require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
//         s.players[_playerId].status = 100; //set status to bridging 
//         PlayerSlotLib.Player storage player = s.players[_playerId];
//         uint256 chainId;
//         uint256 baseId;
//         if (!br.origin[_playerId]) { //have not bridged before
//             chainId = block.chainid; // set origin chain to this chain
//             baseId = _playerId;
//             br.origin[_playerId] = true;
//         } else {
//             chainId = br.playerToBaseChain[_playerId];
//             baseId = br.chainToPlayerId[chainId][_playerId];
//         }
//         BridgeFormat memory bridgeFormat = BridgeFormat(
//             player.playerClass,
//             player.level,
//             player.xp,
//             player.strength,
//             player.health,
//             player.magic,
//             player.maxMana,
//             player.agility,
//             chainId, 
//             baseId,
//             player.name, 
//             player.male
//         );
//         return bridgeFormat;
//     }


//     function _remintPlayer(BridgeFormat memory _format) internal {
//         PlayerStorage storage s = diamondStorage();
//         BridgeStorage storage br = diamondStorageBridge();

//         if (br.chainToPlayerId[_format.baseChain][_format.baseId] > 0) { //if they have been here before

//         } else {

//         }
//     }

//     /// @notice Mints a new player
//     /// @param _name The name of the player
//     /// @param _isMale The gender of the player
//     function _mint(string memory _name, bool _isMale, uint256 _class) internal {
//         PlayerStorage storage s = diamondStorage();
//         //require(s.playerCount <= 500);
//         require(!s.usedNames[_name], "name is taken");
//         require(_class <= 2);
//         require(bytes(_name).length <= 10);
//         require(bytes(_name).length >= 3);
//         s.playerCount++;
//         string memory uri;
//         if (_class == 0) {
//             //warrior
//             _isMale
//                 ? uri = "https://ipfs.io/ipfs/QmV5pSsMGGMLW3Y9yQ8qSLSMDQakdnjhjS4k5he6mJyPeH"
//                 : uri = "https://ipfs.io/ipfs/QmfBNHpxpwUNgtw6iXBxKXLbVxom8mpdBsgqZZy59pRM5C";
//             s.players[s.playerCount] = PlayerSlotLib.Player(
//                 1, //level
//                 0, //xp 
//                 0, //status
//                 11, //strength
//                 12, //health
//                 12, //currentHealth
//                 10, //magic
//                 10, //mana
//                 10, //maxMana
//                 10, //agility
//                 1,
//                 1,
//                 1,
//                 1,
//                 11, //defense
//                 _name,
//                 uri,
//                 _isMale,
//                 PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
//                 _class
//             );
//         } else if (_class == 1) {
//             //assasin
//             _isMale
//                 ? uri = "https://ipfs.io/ipfs/QmQXeYe9rxRkkqfEB7DrZRSG2S1yrNgj64V8m6v7KetzQd"
//                 : uri = "https://ipfs.io/ipfs/QmUqZKRudnang1GXbD2nHHwmJfNNBFQVdmoH8WAneaii5h";
//             s.players[s.playerCount] = PlayerSlotLib.Player(
//                 1, //level
//                 0, //xp
//                 0, //status
//                 11, //strength
//                 11, //health
//                 11, //currentHealth
//                 10, //magic
//                 10, //mana
//                 10, //maxMana
//                 12, //agility
//                 1,
//                 1,
//                 1,
//                 1,
//                 10, //defense
//                 _name,
//                 uri,
//                 _isMale,
//                 PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
//                 _class
//             );
//         } else if (_class == 2) {
//             //mage
//             _isMale
//                 ? uri = "https://ipfs.io/ipfs/QmUbWxUd8sX4MZojKERUPmPu9YtAYfYroBS4Te1HJEKucy"
//                 : uri = "https://ipfs.io/ipfs/QmbVABt9sKpNUa8DgMJde3DBCQyorSCT9V1Dzd6cJ8ZUmP";
//             s.players[s.playerCount] = PlayerSlotLib.Player(
//                 1, //level
//                 0, //xp
//                 0, //status
//                 10, //strength
//                 10, //health
//                 10, //currentHealth
//                 12, //magic
//                 12, //mana
//                 12, //maxMana
//                 10, //agility
//                 1,
//                 1,
//                 1,
//                 1,
//                 10, //defense
//                 _name,
//                 uri,
//                 _isMale,
//                 PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
//                 _class
//             );
//         }
//         s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
//         s.usedNames[_name] = true;
//         s.owners[s.playerCount] = msg.sender;
//         s.addressToPlayers[msg.sender].push(s.playerCount);
//         s.balances[msg.sender]++;
//     }










//     function _createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) internal {
//         BridgeStorage storage br = diamondStorageBridge();
//         br.chainData[_chainId] = ChainData(_chainId, _name, _portal, _diamond);
//     }

//     function _getChainData(uint256 _chainId) internal view returns (ChainData memory) {
//         BridgeStorage storage br = diamondStorageBridge();
//         return br.chainData[_chainId];
//     }

// }



// contract BridgeFacet is ERC721FacetInternal {

//     event BridgeCreated(uint256 indexed _chainId, uint256 indexed _portal, uint256 indexed _diamond);
//     event BridgePlayer(uint256 indexed _playerId, BridgeFormat _format);
//     event ReMintPlayer(BridgeFormat _format);

//     IOmniPortal public omni;

//     function reMintPlayer(BridgeFormat memory _format) public {
        
//     }


//     function bridgePlayer(uint256 _playerId, uint256 _chainId) public {
//         ChainData storage chainData = getChainData(_chainId);
//         //omni = IOmniPortal(0xc0400275F85B45DFd2Cfc838dA8Ee4214B659e25);
//         omni = IOmniPortal(chainData.portal);
//         BridgeFormat storage bridgeFormat = BridgeStorageLib._bridgePlayer(_playerId, _chainId);
//         omni.sendXChainTx(
//             chainData.name, // destination rollup
//             chainData.diamond, // contract on destination rollup
//             0, // msg.value
//             100_000, // gas limit
//             abi.encodeWithSignature("reMintPlayer((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256uint256string,bool))", bridgeFormat)
//         );
//         emit BridgePlayer(_playerId, bridgeFormat);
//     }


//     function createBridge(uint256 _chainId, string memory _name, address _portal, address _diamond) public {
//         BridgeStorageLib._createBridge(_chainId, _name, _portal, _diamond);
//         emit BridgeCreated(_chainId, _portal, _diamond);
//     }

//     function getChainData(uint256 _chainId) public view returns(ChainData memory) {
//         return BridgeStorageLib._getChainData(_chainId);
//     }

// }