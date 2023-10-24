// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import {ERC721Storage} from "../ERC721Storage.sol";
import {ERC721FacetInternal} from "./ERC721FacetInternal.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20Facet} from "@okg/erc20-diamond/contracts/facets/ERC20Facet.sol";

struct PlayerListing {
    address payable seller;
    uint256 playerId;
    uint256 price;
    uint256 pointer;
    uint256 addressPointer;
}

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

struct Treasure {
    uint256 id;
    uint256 rank;
    uint256 pointer;
    string name;
    string uri;
}

library ExchangeStorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant EXCHANGE_STORAGE_POSITION = keccak256("exchange.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant EQUIPMENT_STORAGE_POSITION = keccak256("equipment.test.storage.a");
    bytes32 constant TREASURE_STORAGE_POSITION = keccak256("treasure.test.storage.a");

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
        mapping(uint256 => PlayerListing) playerListings;
        mapping(address => uint256[]) addressToPlayerListings;
        uint256[] playerListingsArray;
        mapping(uint256 => EquipmentListing) equipmentListings;
        mapping(address => uint256[]) addressToEquipmentListings;
        uint256[] equipmentListingsArray;
        mapping(uint256 => TreasureListing) TreasureListings;
        mapping(address => uint256[]) addressToTreasureListings;
        uint256[] treasureListingsArray;
    }

    struct EquipmentStorage {
        uint256 equipmentCount;
        mapping(uint256 => uint256) owners; //maps equipment id to player id
        mapping(uint256 => Equipment) equipment;
        mapping(uint256 => uint256[]) playerToEquipment;
        mapping(uint256 => uint256) cooldown;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct TreasureStorage {
        uint256 treasureCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Treasure) treasures;
        mapping(uint256 => uint256[]) playerToTreasure;
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

    function diamondStorageEquipment() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTreasure() internal pure returns (TreasureStorage storage ds) {
        bytes32 position = TREASURE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _mintGoldERC20(address _facetAddress, uint256 _amount) internal {
        CoinStorage storage c = diamondStorageCoin();
        // TODO - remove this - only for testing
        c.goldBalance[msg.sender] += 10;
        require(_amount <= c.goldBalance[msg.sender], "ExchangeFacet: You do not have enough gold to mint");
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);

        ERC20Facet tokenFacet = ERC20Facet(_facetAddress); // Address of the diamond
        if (_amount > 0) {
            uint256 tokenAmount = _amount * 1 ether;
            uint256 tokenFee = tokenAmount * 1 / 100; // 1% fee
            uint256 tokensToUser = tokenAmount - tokenFee;
            tokenFacet.mint(msg.sender, tokensToUser);
            tokenFacet.mint(feeRecipient, tokenFee); // 1% fee
            c.goldBalance[msg.sender] -= _amount;
        }
    }

    function _claimGoldfromERC20(address _facetAddress, uint256 _amount) internal {
        CoinStorage storage c = diamondStorageCoin();
        ERC20Facet tokenFacet = ERC20Facet(_facetAddress); // Address of the diamond
        uint256 tokenBalance = tokenFacet.balanceOf(msg.sender);
        require(tokenBalance / 1 ether >= _amount, "ExchangeFacet: You do not have enough tokens to claim");
        address feeRecipient = address(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        if (_amount > 0) {
            // Burn the tokens for the gold
            uint256 tokenAmount = _amount * 1 ether;
            uint256 tokenFee = tokenAmount * 1 / 100; // 1% fee
            uint256 tokensToBurn = tokenAmount - tokenFee;
            tokenFacet.burn(msg.sender, tokensToBurn);
            tokenFacet.transferFrom(msg.sender, feeRecipient, tokenFee);
            c.goldBalance[msg.sender] += _amount;
        }
    }

    function _createPlayerListing(uint256 _playerId, uint256 _price) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExchangeStorage storage ex = diamondStorageEx();
        require(s.owners[_playerId] == msg.sender, "You do not own this player"); //require that sender owns the player
        require(s.players[_playerId].status == 0, "Player staus is idle"); //require that player is idle
        s.players[_playerId].status = 99; //set the status code to 99
        ex.playerListings[_playerId] = PlayerListing(
            payable(msg.sender),
            _playerId,
            _price,
            ex.playerListingsArray.length,
            ex.addressToPlayerListings[msg.sender].length
        ); //create the listing and map
        ex.playerListingsArray.push(_playerId); //push to the total equipment listing array
        ex.addressToPlayerListings[msg.sender].push(_playerId); //push to the equipemnt array owned by the address
    }

    function _purchasePlayer(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExchangeStorage storage ex = diamondStorageEx();
        address seller = ex.playerListings[_playerId].seller;
        require(s.owners[_playerId] == ex.playerListings[_playerId].seller, "this item as sold elsewhere"); //check if player has already sold on another exchange

        //remove from total listing array
        uint256 rowToDelete = ex.playerListings[_playerId].pointer;
        uint256 keyToMove = ex.playerListingsArray[ex.playerListingsArray.length - 1];
        ex.playerListingsArray[rowToDelete] = keyToMove;
        ex.playerListings[keyToMove].pointer = rowToDelete;
        ex.playerListingsArray.pop();

        //remove the players to address to listings array
        uint256 rowToDeleteAddress = ex.playerListings[_playerId].addressPointer;
        uint256 keyToMoveAddress = ex.addressToPlayerListings[seller][ex.addressToPlayerListings[seller].length - 1];
        ex.addressToPlayerListings[seller][rowToDeleteAddress] = keyToMoveAddress;
        ex.playerListings[keyToMoveAddress].addressPointer = rowToDeleteAddress; //change the pointer of the listing
        ex.addressToPlayerListings[seller].pop();

        s.players[_playerId].status = 0; //return player to idle
        delete ex.playerListings[_playerId]; //delete the player listing form the lisitngs map
    }

    function _deListPlayer(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExchangeStorage storage ex = diamondStorageEx();
        require(ex.playerListings[_playerId].seller == msg.sender, "caller must be the owner of the listing"); //make sure caller is the owner
        address seller = ex.playerListings[_playerId].seller;

        //remove from total listing array
        uint256 rowToDelete = ex.playerListings[_playerId].pointer;
        uint256 keyToMove = ex.playerListingsArray[ex.playerListingsArray.length - 1];
        ex.playerListingsArray[rowToDelete] = keyToMove;
        ex.playerListings[keyToMove].pointer = rowToDelete;
        ex.playerListingsArray.pop();

        //remove the players to address to listings array
        uint256 rowToDeleteAddress = ex.playerListings[_playerId].addressPointer;
        uint256 keyToMoveAddress = ex.addressToPlayerListings[seller][ex.addressToPlayerListings[seller].length - 1];
        ex.addressToPlayerListings[seller][rowToDeleteAddress] = keyToMoveAddress;
        ex.playerListings[keyToMoveAddress].addressPointer = rowToDeleteAddress; //change the pointer of the listing
        ex.addressToPlayerListings[seller].pop();

        s.players[_playerId].status = 0; //return player to idle
        delete ex.playerListings[_playerId]; //delete the player listing form the lisitngs map
    }

    function _getPlayerListingsByAddress(address _address) internal view returns (uint256[] memory) {
        ExchangeStorage storage ex = diamondStorageEx();
        return ex.addressToPlayerListings[_address];
    }

    function _getPlayerListing(uint256 _listingId) internal view returns (PlayerListing memory) {
        ExchangeStorage storage ex = diamondStorageEx();
        return ex.playerListings[_listingId];
    }

    function _getAllPlayerListings() internal view returns (uint256[] memory) {
        ExchangeStorage storage ex = diamondStorageEx();
        return ex.playerListingsArray;
    }

    function _getTotalPricePlayer(uint256 _playerId) internal view returns (uint256) {
        ExchangeStorage storage ex = diamondStorageEx();
        return ((ex.playerListings[_playerId].price * (105)) / 100);
    }

    function _owners(uint256 _playerId) internal view returns (address) {
        PlayerStorage storage s = diamondStoragePlayer();
        return s.owners[_playerId];
    }
}

contract ExchangeFacet is ERC721FacetInternal, ReentrancyGuard {
    event CreateEquipmentListing(address indexed _from, uint256 indexed _playerId, uint256 _price);
    event PurchaseEquipmentLisitng(address indexed _to, uint256 _id);
    event CreatePlayerListing(address indexed _from, uint256 indexed _playerId, uint256 _price);
    event PurchasePlayerListing(address indexed _to, uint256 _id);
    event DelistPlayer(address indexed _from, uint256 indexed _playerId);

    function transferPlayer(address _to, uint256 _playerId) public nonReentrant {
        _transfer(msg.sender, _to, _playerId);
    }

    function createPlayerListing(uint256 _playerId, uint256 _price) public nonReentrant {
        ExchangeStorageLib._createPlayerListing(_playerId, _price);
        emit CreatePlayerListing(msg.sender, _playerId, _price);
    }

    function mintGoldERC20(address _facetAddress, uint256 _amount) public nonReentrant {
        ExchangeStorageLib._mintGoldERC20(_facetAddress, _amount);
    }

    function claimGoldfromERC20(address _facetAddress, uint256 _amount) public nonReentrant {
        ExchangeStorageLib._claimGoldfromERC20(_facetAddress, _amount);
    }

    function purchasePlayer(uint256 _playerId) public payable nonReentrant {
        address payable feeAccount = payable(0x08d8E680A2d295Af8CbCD8B8e07f900275bc6B8D);
        PlayerListing memory listing = ExchangeStorageLib._getPlayerListing(_playerId);
        require(msg.value == listing.price, "Send the exact amount");
        ExchangeStorageLib._purchasePlayer(_playerId);
        require(_isApprovedOrOwner(listing.seller, _playerId), "ERC721: seller is not token owner or approved");
        _transfer(listing.seller, msg.sender, _playerId);
        uint256 royalty = ((listing.price * 105) - (listing.price * 100)) / 100;
        uint256 to_seller = listing.price - royalty;
        (bool sentSeller,) = listing.seller.call{value: to_seller}("");
        require(sentSeller, "Failed to send Ether to the seller");
        (bool sentRoyalty,) = feeAccount.call{value: royalty}("");
        require(sentRoyalty, "Failed to send Ether to the fee account");
        emit PurchasePlayerListing(msg.sender, _playerId);
    }

    function deListPlayer(uint256 _playerId) public {
        ExchangeStorageLib._deListPlayer(_playerId);
        emit DelistPlayer(msg.sender, _playerId);
    }

    function getPlayerListing(uint256 _playerId) public view returns (PlayerListing memory) {
        return ExchangeStorageLib._getPlayerListing(_playerId);
    }

    function getPlayerListingsByAddress(address _address) public view returns (uint256[] memory) {
        return ExchangeStorageLib._getPlayerListingsByAddress(_address);
    }

    function getAllPlayerListings() public view returns (uint256[] memory) {
        return ExchangeStorageLib._getAllPlayerListings();
    }

    function owners(uint256 _playerId) public view returns (address) {
        return ExchangeStorageLib._owners(_playerId);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
