// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "../libraries/PlayerSlotLib.sol";


// struct BasicHealthPotionSchema {
//     uint256 basicHealthPotionSchemaId;
//     uint256 value;
//     uint256 cost;
//     string name;
//     string uri;
// }
// struct BasicManaPotionSchema {
//     uint256 basicManaPotionSchemaId;
//     uint256 value;
//     uint256 cost;
//     string name;
//     string uri;
// }

// // stat {
// //     0: strength;
// //     1: health;
// //     2: agility;
// //     3: magic;
// //     4: defense;
// //     5: maxMana;
// //     6: luck;
// // }

// struct Treasure {
//     uint256 id;
//     uint256 rank;
//     uint256 pointer;
//     string name;
// }

// library StorageLib {
//     bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
//     bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
//     bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");

//     using PlayerSlotLib for PlayerSlotLib.Player;
//     using PlayerSlotLib for PlayerSlotLib.Slot;

//     struct PlayerStorage {
//         uint256 totalSupply;
//         uint256 playerCount;
//         mapping(uint256 => address) owners;
//         mapping(uint256 => PlayerSlotLib.Player) players;
//         mapping(address => uint256) balances;
//         mapping(address => mapping(address => uint256)) allowances;
//         mapping(string => bool) usedNames;
//         mapping(address => uint256[]) addressToPlayers;
//     }

//     struct PotionStorage {
//         uint256 BasicHealthPotionSchemaCount;
//         uint256 BasicManaPotionSchemaCount;
//         mapping(uint256 => BasicHealthPotionSchema) basicHealthPotionSchema;
//         mapping(uint256 => mapping(uint256 => uint256)) basicHealthPotionToPlayer;
//     }

//     struct CoinStorage {
//         mapping(address => uint256) goldBalance;
//         mapping(address => uint256) gemBalance;
//         mapping(address => uint256) totemBalance;
//         mapping(address => uint256) diamondBalance;
//     }

//     struct ResourceStorage {
//         uint256 treasureCount;
//         mapping(uint256 => address) owners;
//         mapping(uint256 => Treasure) treasures;
//         mapping(uint256 => uint256[]) playerToTreasure;
//     }

//     function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
//         bytes32 position = PLAYER_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }
//     function diamondStorageCoin() internal pure returns (CoinStorage storage ds) {
//         bytes32 position = COIN_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }
//     function diamondStoragePotion() internal pure returns (PotionStorage storage ds) {
//         bytes32 position = POTION_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }


//     function _createBasicHealthPotion(uint256 _value, uint256 _cost, string memory _name, string memory _uri) internal {
//         PotionStorage storage p = diamondStoragePotion();
//         p.BasicHealthPotionSchemaCount++;
//         p.basicHealthPotioSchema
//     }
  










// }

// contract ShopFacet {




//     //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
// }