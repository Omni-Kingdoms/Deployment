// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

struct EquipmentListing {
    address payable seller;
    uint256 equipmentId;
    uint256 price;
    uint256 pointer;
    uint256 addressPointer;
}

struct TreasureListing {
    address payable seller;
    uint256 treasureId;
    uint256 price;
    uint256 pointer;
    uint256 addressPointer;
}

library ExchangeStorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant EXCHANGE_STORAGE_POSITION = keccak256("exchange.test.storage.a");
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

    struct ExchangeStorage {
        mapping(uint256 => EquipmentListing) EquipmentListings;
        mapping(address => uint256[]) addressToEquipmentListings;
        uint256[] equipmentListingsArray;
        mapping(uint256 => TreasureListing) TreasureListings;
        mapping(address => uint256[]) addressToTreasureListings;
        uint256[] treasureListingsArray;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageEx() internal pure returns (ExchangeStorage storage ds) {
        bytes32 position = EXCHANGE_STORAGE_POSITION;
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

    function _createEquipmentListing(uint256 _id, uint256 _price) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExchangeStorage storage ex = diamondStorageEx();
        require(s.owners[_id] == msg.sender, "Not owner of player"); //ownerOf
        require(s.players[_id].status == 0, "PlayerSlotLib.Player is not idle"); //make sure player is idle
        e.listingsMap[_id] = PlayerListing(payable(msg.sender), _id, _price, e.listingsArray.length); //create the listing and map
        
    }

    function _purchasePlayer(uint256 _listingId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExchangeStorage storage e = diamondStorageEx();
        CoinStorage storage c = diamondStorageCoin();
        uint256 price = e.listingsMap[_listingId].price;
        require(c.goldBalance[msg.sender] >= price, "Insufficient funds"); //check if buyer has enough value
        uint256 playerId = e.listingsMap[_listingId].playerId;
        s.owners[playerId] = msg.sender; //transfer ownership

        s.addressToPlayers[msg.sender].push(e.listingsMap[_listingId].playerId); //add id to players array

        address seller = e.listingsMap[_listingId].seller;
        c.goldBalance[msg.sender] -= price; //deduct balance from buyer
        c.goldBalance[seller] += price; //increase balance for seller

        uint256 rowToDelete = e.listingsMap[_listingId].pointer;
        uint256 keyToMove = e.listingsArray[e.listingsArray.length - 1];
        e.listingsArray[rowToDelete] = keyToMove;
        e.listingsMap[keyToMove].pointer = rowToDelete;
        e.listingsArray.pop();
        delete e.listingsMap[_listingId];
        s.balances[msg.sender]++; //increment the balance
    }

    function _getListings(address _address) internal view returns (uint256[] memory) {
        ExchangeStorage storage e = diamondStorageEx();
        return e.addressToListings[_address];
    }

    function _getListing(uint256 _listingId)
        internal
        view
        returns (address payable seller, uint256 playerId, uint256 price)
    {
        ExchangeStorage storage e = diamondStorageEx();
        PlayerListing memory listing = e.listingsMap[_listingId];
        return (payable(listing.seller), listing.playerId, listing.price);
    }

    function _getAllListings() internal view returns (uint256[] memory) {
        ExStorage storage e = diamondStorageEx();
        return e.listingsArray;
    }
}

contract ExchangeFacet {
    event List(address indexed _from, uint256 indexed _playerId, uint256 _price);
    event Purchase(address indexed _to, uint256 _id);

    function crateListing(uint256 _id, uint256 _price) public {
        ExchangeStorageLib._createListing(_id, _price);
        emit List(msg.sender, _id, _price);
    }

    function purchasePlayer(uint256 _listingId) public {
        ExchangeStorageLib._purchasePlayer(_listingId);
        emit Purchase(msg.sender, _listingId);
    }

    function getListings(address _address) public view returns (uint256[] memory) {
        return ExchangeStorageLib._getListings(_address);
    }

    function getLisitng(uint256 _listingId)
        public
        view
        returns (address payable seller, uint256 playerId, uint256 price)
    {
        return ExchangeStorageLib._getListing(_listingId);
    }

    function getAllListings() public view returns (uint256[] memory) {
        return ExchangeStorageLib._getAllListings();
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
