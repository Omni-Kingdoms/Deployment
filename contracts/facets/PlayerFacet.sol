// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    struct TransferStorage {
        mapping(string => address) ourContractOnChains;
        IGateway gatewayContract;
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

    function _setContractOnChain(string calldata _chainId, address _contractAddress) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.ourContractOnChains[_chainId] = _contractAddress;
    }

    function _setGateway(address gateway) internal {
        TransferStorage storage s = diamondStorageTransfer();
        s.gatewayContract = IGateway(gateway);
    }

    function _transferRemote(
        string memory _destination,
        address _recipient,
        uint256 _playerId,
        bytes memory _requestMetadata
    ) internal {
        PlayerStorage storage s = diamondStorage();
        TransferStorage storage t = diamondStorageTransfer();
        require(s.owners[_playerId] == msg.sender);
        require(
            keccak256(abi.encodePacked(t.ourContractOnChains[_destination])) != keccak256(abi.encodePacked("")),
            "contract on dest not set"
        );

        PlayerSlotLib.Player memory player = _getPlayer(_playerId);

        //Delete the player from the source chain
        for (uint256 i = 0; i < s.balances[msg.sender]; i++) {
            if (s.addressToPlayers[msg.sender][i] == _playerId) {
                delete s.addressToPlayers[msg.sender][i];
                break;
            }
        }
        s.balances[msg.sender]--;

        TransferParams memory transferParams =
            TransferParams({nftId: _playerId, playerId: _playerId, playerData: player, recipient: _recipient});

        // sending the transfer params struct to the destination chain as payload.
        bytes memory packet = abi.encode(transferParams);
        bytes memory requestPacket = abi.encode(t.ourContractOnChains[_destination], packet);

        t.gatewayContract.iSend{value: msg.value}(1, 0, string(""), _destination, _requestMetadata, requestPacket);
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

        chainId = abi.encode(srcChainId);
    }

    function _mintCrossChainPlayer(PlayerSlotLib.Player memory _player, address _recipient) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_player.name], "name is taken");
        require(bytes(_player.name).length <= 10);
        require(bytes(_player.name).length >= 3);
        s.playerCount++;
        s.players[s.playerCount] = PlayerSlotLib.Player(
            _player.level,
            _player.xp,
            _player.status,
            _player.strength,
            _player.health,
            _player.magic,
            _player.mana,
            _player.agility,
            _player.luck,
            _player.wisdom,
            _player.haki,
            _player.perception,
            _player.defense,
            _player.name,
            _player.uri,
            _player.male,
            PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0)
        );
        s.slots[s.playerCount] = PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0);
        s.usedNames[_player.name] = true;
        s.owners[s.playerCount] = _recipient;
        s.addressToPlayers[_recipient].push(s.playerCount);
        s.balances[_recipient]++;
    }

    /// @notice Mints a new player
    /// @param _name The name of the player
    /// @param _uri The IPFS URI of the player metadata
    /// @param _isMale The gender of the player
    function _mint(string memory _name, string memory _uri, bool _isMale) internal {
        PlayerStorage storage s = diamondStorage();
        require(!s.usedNames[_name], "name is taken");
        require(bytes(_name).length <= 10);
        require(bytes(_name).length >= 3);
        s.playerCount++;
        s.players[s.playerCount] = PlayerSlotLib.Player(
            1, 0, 0, 1, 10, 10, 1, 1, 1, 1, 1, 1, 1, 1, _name, _uri, _isMale, PlayerSlotLib.Slot(0, 0, 0, 0, 0, 0, 0)
        );
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
        for (uint256 i = 0; i < s.balances[msg.sender]; i++) {
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
}

/// @title Player Facet
/// @dev Contract managing interaction with player data
contract PlayerFacet is ERC721FacetInternal {
    // contract PlayerFacet {
    using Strings for uint256;

    event Mint(uint256 indexed id, address indexed owner, string name, string uri);
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
    function setContractOnChain(string calldata _chainId, address _contractAddress) external {
        PlayerStorageLib._setContractOnChain(_chainId, _contractAddress);
    }

    // Set the gateway contract address from https://docs.routerprotocol.com/develop/message-transfer-via-crosstalk/evm-guides/your-first-crosschain-nft-contract/deploying-your-nft-contract
    function setGateway(address gateway) external {
        PlayerStorageLib._setGateway(gateway);
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
     * @notice Transfers `_amountOrId` token to `_recipient` on `_destination` domain.
     * @dev Delegates transfer logic to `_transferFromSender` implementation.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _destination The identifier of the destination chain.
     * @param _recipient The address of the recipient on the destination chain.
     */
    function transferRemote(
        string calldata _destination,
        address _recipient,
        uint256 _playerId,
        bytes memory _requestMetadata
    ) public payable {
        _burn(_playerId);
        PlayerStorageLib._transferRemote(_destination, _recipient, _playerId, _requestMetadata);
        emit SentTransferRemote(_destination, _recipient, _playerId);
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
    /// @param _uri The IPFS URI of the player metadata
    /// @param _isMale The gender of the player
    function mint(string memory _name, string memory _uri, bool _isMale) external {
        PlayerStorageLib._mint(_name, _uri, _isMale);
        uint256 count = playerCount();
        emit Mint(count, msg.sender, _name, _uri);

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

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
