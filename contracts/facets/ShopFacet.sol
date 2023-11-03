// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";


struct BasicPotionSchema {
    uint256 basicHealthPotionSchemaId;
    uint256 value;
    uint256 cost;
    bool isHealth;
    string name;
    string uri;
}

// stat {
//     0: strength;
//     1: health;
//     2: agility;
//     3: magic;
//     4: defense;
//     5: maxMana;
//     6: luck;
// }


library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");

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

    struct PotionStorage {
        uint256 BasicPotionSchemaCount;
        mapping(uint256 => BasicPotionSchema) basicPotionSchema;
        mapping(uint256 => mapping(uint256 => uint256)) basicPotionToPlayer;
    }

    struct CoinStorage {
        uint256 goldCount;
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
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
    function diamondStoragePotion() internal pure returns (PotionStorage storage ds) {
        bytes32 position = POTION_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }


    function _createBasicPotion(uint256 _value, uint256 _cost, bool _isHealth, string memory _name, string memory _uri) internal {
        PotionStorage storage p = diamondStoragePotion();
        p.BasicPotionSchemaCount++;
        p.basicPotionSchema[p.BasicPotionSchemaCount] = BasicPotionSchema(
            p.BasicPotionSchemaCount,
            _value,
            _cost,
            _isHealth,
            _name,
            _uri
        );
    }
    
    function _purchaseBasicPotion(uint256 _playerId, uint256 _basicPotionSchemaId) internal {
        PotionStorage storage p = diamondStoragePotion();
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        uint256 cost = p.basicPotionSchema[_basicPotionSchemaId].cost;
        require(c.goldBalance[msg.sender] >= cost); //check user has enough gold
        p.basicPotionToPlayer[_basicPotionSchemaId][_playerId]++; //add potion to count
        c.goldBalance[msg.sender] -= cost; //deduct gold balance
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        c.goldBalance[feeRecipient] += cost; //increment fee account gold
    }

    function _consumeBasicPotion(uint256 _playerId, uint256 _basicPotionSchemaId) internal {
        PotionStorage storage p = diamondStoragePotion();
        PlayerStorage storage s = diamondStoragePlayer();
        require(s.players[_playerId].status == 0, "you are not idle"); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
        require(p.basicPotionToPlayer[_basicPotionSchemaId][_playerId] >= 1, "no pot fool"); //check that they have one
        //BasicHealthPotionSchema memory potion = p.basicHealthPotionSchema[_basicPotionSchemaId];
        uint256 value = p.basicPotionSchema[_basicPotionSchemaId].value;
        if (p.basicPotionSchema[_basicPotionSchemaId].isHealth) {
            value >= s.players[_playerId].health - s.players[_playerId].currentHealth ?
                s.players[_playerId].currentHealth = s.players[_playerId].health
                :
                s.players[_playerId].currentHealth += value;
        } else {
            value >= s.players[_playerId].maxMana - s.players[_playerId].mana ?
                s.players[_playerId].mana = s.players[_playerId].maxMana
                :
                s.players[_playerId].mana += value;
        }
        p.basicPotionToPlayer[_basicPotionSchemaId][_playerId]--;
    }

    function _getBaiscPotionCount(uint256 _playerId, uint256 _basicPotionSchemaId) internal view returns(uint256) {
        PotionStorage storage p = diamondStoragePotion();
        return p.basicPotionToPlayer[_basicPotionSchemaId][_playerId];
    }

    function _getBasicPotion(uint256 _basicPotionSchemaId) internal view returns (BasicPotionSchema memory) {
        PotionStorage storage p = diamondStoragePotion();
        return p.basicPotionSchema[_basicPotionSchemaId];
    }

    function _getBasicPotionSchemaCount() internal view returns (uint256) {
        PotionStorage storage p = diamondStoragePotion();
        return p.BasicPotionSchemaCount;
    }


}

contract ShopFacet {

    event CreateBasicPotion(uint256 indexed _basicPotionSchemaId, BasicPotionSchema potionSchema);
    event PurchaseBasicPotion(uint256 _playerId, uint256 indexed _basicPotionSchemaId);
    event ConsumeBasicPotion(uint256 _playerId, uint256 indexed _basicPotionSchemaId);
    

    function createBasicPotion(uint256 _value, uint256 _cost, bool _isHealth, string memory _name, string memory _uri) public {
        StorageLib._createBasicPotion(_value, _cost, _isHealth, _name, _uri);
        uint256 id = StorageLib._getBasicPotionSchemaCount();
        emit CreateBasicPotion(id, getBasicPotion(id));
    }

    function purchaseBasicPotion(uint256 _playerId, uint256 _basicPotionSchemaId) public {
        StorageLib._purchaseBasicPotion(_playerId, _basicPotionSchemaId);
        emit PurchaseBasicPotion(_playerId, _basicPotionSchemaId);
    }

    function consumeBasicHealthPotion(uint256 _playerId, uint256 _basicPotionSchemaId) public {
        StorageLib._consumeBasicPotion(_playerId, _basicPotionSchemaId);
        emit ConsumeBasicPotion(_playerId, _basicPotionSchemaId);
    }

    function getBaiscPotionCount(uint256 _playerId, uint256 _basicPotionSchemaId) public view returns(uint256) {
        return StorageLib._getBaiscPotionCount(_playerId, _basicPotionSchemaId);
    }

    function getBasicPotion(uint256 _basicPotionSchemaId) public view returns (BasicPotionSchema memory) {
        return StorageLib._getBasicPotion(_basicPotionSchemaId);
    }

    function getBasicPotionSchemaCount() public view returns (uint256) {
        return StorageLib._getBasicPotionSchemaCount();
    }


    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}