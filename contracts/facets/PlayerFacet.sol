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

    // transfer params struct where we specify which NFTs should be transferred to
    // the destination chain and to which address
    struct TransferParams {
        uint256 nftId;
        uint256 playerId;
        PlayerSlotLib.Player playerData;
        address recipient;
    }

    struct TransferRemote {
        string _destination;
        address _recipientAsAddress;
        string _recipientAsString;
        uint256 _playerId;
    }

    struct TransferStorage {
        mapping(string => string) ourContractOnChains;
        IGateway gatewayContract;
        uint256 test;
    }

    /// @dev Function to retrieve diamond storage slot for player data. Returns a reference.
    function diamondStorage() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTransfer() internal pure returns (TransferStorage storage ds) {
        bytes32 position = TRANSFER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _setContractOnChain(string calldata _chainId, string calldata _contractAddress) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.ourContractOnChains[_chainId] = _contractAddress;
        s.test++;
    }

    function _setGateway(address _gateway, string calldata _feePayer) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.gatewayContract = IGateway(_gateway);

        s.gatewayContract.setDappMetadata(_feePayer);
    }

    function _getTransferParams(string calldata _chainId)
        internal
        view
        returns (address gateway, string storage contractOnChain, uint256 test)
    {
        TransferStorage storage s = diamondStorageTransfer();

        gateway = address(s.gatewayContract);
        contractOnChain = s.ourContractOnChains[_chainId];
        test = s.test;
    }

    function _deletePlayer(address _sender, uint256 _playerId) internal {
        PlayerStorage storage s = diamondStorage();
        require(s.owners[_playerId] == _sender);
        require(_playerId <= s.playerCount, "Player does not exist");

        // Reset Player data - TODO
        // PlayerSlotLib.Player storage playerToDelete = s.players[_playerId];
        // playerToDelete = PlayerSlotLib.Player({/*...initialize with default values...*/});

        // Reset owner data
        s.owners[_playerId] = address(0);

        // Reduce the balance of the player's owner
        s.balances[s.owners[_playerId]] = 0;

        // Clear allowances
        s.allowances[s.owners[_playerId]][address(this)] = 0;

        // Decrement playerCount
        s.playerCount--;

        // Remove player from the addressToPlayers mapping
        uint256[] storage playerIds = s.addressToPlayers[s.owners[_playerId]];
        for (uint256 i = 0; i < playerIds.length; i++) {
            if (playerIds[i] == _playerId) {
                playerIds[i] = playerIds[playerIds.length - 1];
                playerIds.pop();
                break;
            }
        }

        // Delete player's slot
        delete s.slots[_playerId];
    }

    function _transferRemote(TransferRemote memory params)
        internal
        returns (address gatewayContractAddress, bytes memory requestPacket)
    {
        TransferStorage storage t = diamondStorageTransfer();
        require(
            keccak256(abi.encodePacked(t.ourContractOnChains[params._destination])) != keccak256(abi.encodePacked("")),
            "contract on dest not set"
        );

        PlayerStorage storage s = diamondStorage();
        PlayerSlotLib.Player memory player = s.players[params._playerId];

        TransferParams memory transferParams = TransferParams({
            nftId: params._playerId,
            playerId: params._playerId,
            playerData: player,
            recipient: params._recipientAsAddress
        });

        // sending the transfer params struct to the destination chain as payload.
        bytes memory packet = abi.encode(transferParams);
        requestPacket = abi.encode(t.ourContractOnChains[params._destination], packet);
        gatewayContractAddress = address(t.gatewayContract);

        _deletePlayer(msg.sender, params._playerId);
        t.test++;
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param packet the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    function _iReceive(bytes memory packet, string memory srcChainId)
        internal
        returns (address recipient, uint256 nftId, bytes memory chainId)
    {
        TransferStorage storage t = diamondStorageTransfer();
        require(msg.sender == address(t.gatewayContract), "only gateway");
        // decoding our payload
        TransferParams memory transferParams = abi.decode(packet, (TransferParams));
        recipient = transferParams.recipient;
        nftId = transferParams.nftId;
        _mintCrossChainPlayer(transferParams.playerData, recipient);
        t.test++;
        chainId = abi.encode(srcChainId);
    }

    function _mintCrossChainPlayer(PlayerSlotLib.Player memory _player, address _recipient) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_player.name], "name is taken");
        require(bytes(_player.name).length <= 10);
        require(bytes(_player.name).length >= 3);
        // require(_playerId > s.playerCount);
        s.playerCount++;
        s.players[s.playerCount] = PlayerSlotLib.Player(
            _player.level,
            _player.xp,
            _player.status,
            _player.strength,
            _player.health,
            _player.currentHealth,
            _player.magic,
            _player.mana,
            _player.maxMana,
            _player.agility,
            _player.luck,
            _player.wisdom,
            _player.haki,
            _player.perception,
            _player.defense,
            _player.name,
            _player.uri,
            _player.male,
            PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0),
            _player.playerClass
        );
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0);
        s.usedNames[_player.name] = true;
        s.owners[s.playerCount] = _recipient;
        s.addressToPlayers[_recipient].push(s.playerCount);
        s.balances[_recipient]++;
    }

    /// @notice Mints a new player
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function _mint(string memory _name, bool _isMale, uint256 _class) internal {
        PlayerStorage storage s = diamondStorage();
        //require(s.playerCount <= 500);
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
                10, //defense
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

    /**
     * @dev Emitted on `transferRemote` when a transfer message is dispatched.
     * @param destination The identifier of the destination chain.
     * @param recipient The address of the recipient on the destination chain.
     * @param playerId The amount of tokens burnt on the origin chain.
     */
    event SentTransferRemote(string destination, address indexed recipient, uint256 playerId);

    function playerCount() public view returns (uint256) {
        return PlayerStorageLib._playerCount();
    }

    // Through this function, set the address of the corresponding contract on the destination chain
    function setContractOnChain(string calldata _chainId, string calldata _contractAddress) external {
        PlayerStorageLib._setContractOnChain(_chainId, _contractAddress);
    }

    // Set the gateway contract address from https://docs.routerprotocol.com/develop/message-transfer-via-crosstalk/evm-guides/your-first-crosschain-nft-contract/deploying-your-nft-contract
    function setGateway(address gateway, string calldata feePayer) external {
        PlayerStorageLib._setGateway(gateway, feePayer);
    }

    function getTransferParams(string calldata _chainId)
        external
        view
        returns (address gateway, string memory contractOnChain, uint256 test)
    {
        (gateway, contractOnChain, test) = PlayerStorageLib._getTransferParams(_chainId);
    }

    /// @notice function to get the request metadata to be used while initiating cross-chain request
    /// @return requestMetadata abi-encoded metadata according to source and destination chains
    function getRequestMetadata(
        uint64 _destGasLimit,
        uint64 _destGasPrice,
        uint64 _ackGasLimit,
        uint64 _ackGasPrice,
        uint128 _relayerFees,
        uint8 _ackType,
        bool _isReadCall,
        bytes memory _asmAddress
    ) public pure returns (bytes memory) {
        bytes memory requestMetadata = abi.encodePacked(
            _destGasLimit, _destGasPrice, _ackGasLimit, _ackGasPrice, _relayerFees, _ackType, _isReadCall, _asmAddress
        );
        return requestMetadata;
    }

    /**
     * @dev Transfers a player to a remote chain using the Router Gateway.
     * @param _destination The name of the destination chain.
     * @param _recipientAsAddress The address of the recipient on the destination chain.
     * @param _recipientAsString The string representation of the recipient on the destination chain.
     * @param _playerId The ID of the player to transfer.
     * @param _requestMetadata Additional metadata to include in the request packet.
     * Requirements:
     * - The player must exist in the local storage.
     * - The player must be burned after the transfer.
     * Emits a {SentTransferRemote} event.
     */
    function transferRemote(
        string calldata _destination,
        address _recipientAsAddress,
        string calldata _recipientAsString,
        uint256 _playerId,
        bytes memory _requestMetadata
    ) public payable {
        // Call the _transferRemote function in the PlayerStorageLib library to get the gateway contract address and request packet.
        (address gatewayContractAddress, bytes memory requestPacket) = PlayerStorageLib._transferRemote(
            PlayerStorageLib.TransferRemote({
                _destination: _destination,
                _recipientAsAddress: _recipientAsAddress,
                _recipientAsString: _recipientAsString,
                _playerId: _playerId
            })
        );

        // Get the Router Gateway contract instance.
        IGateway gatewayContract = IGateway(gatewayContractAddress);

        // Call the iSend function on the Router Gateway contract to send the request packet to the destination chain.
        gatewayContract.iSend{value: msg.value}(1, 0, string(""), _destination, _requestMetadata, requestPacket);

        // Burn the player after the transfer.
        _burn(_playerId);

        // Emit a SentTransferRemote event.
        emit SentTransferRemote(_destination, _recipientAsAddress, _playerId);
    }

    /// @notice function to handle the cross-chain request received from some other chain.
    /// @param packet the payload sent by the source chain contract when the request was created.
    /// @param srcChainId chain ID of the source chain in string.
    function iReceive(
        string memory, // requestSender,
        bytes memory packet,
        string memory srcChainId
    ) internal returns (bytes memory) {
        // decoding our payload
        (address recipient, uint256 nftId, bytes memory toChainId) = PlayerStorageLib._iReceive(packet, srcChainId);
        _safeMint(recipient, nftId);

        return abi.encode(toChainId);
    }

    /// @notice Mints a new player
    /// @dev Emits a Mint event
    /// @dev Calls the _mint function from the PlayerStorageLib
    /// @param _name The name of the player
    /// @param _isMale The gender of the player
    function mint(string memory _name, bool _isMale, uint256 _class) external {
        PlayerStorageLib._mint(_name, _isMale, _class);
        uint256 count = playerCount();
        emit Mint(count, msg.sender, _name, _class);

        //TODO - somehow
        _safeMint(msg.sender, count);
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
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
