// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";
import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";

struct BasicArena {
    uint256 basicArenaId;
    uint256 cost;
    uint256 cooldown;
    uint256 hostId;
    bool open;
    address payable hostAddress;
    string name;
    string url;
}

struct HillArena {
    uint256 hillArenaId;
    uint256 cost;
    uint256 cooldown;
    uint256 hostId;
    bool open;
    address payable hostAddress;
    string name;
    string url;
}

library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant ARENA_STORAGE_POSITION = keccak256("Arena.test.storage.a");

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
        mapping(uint256 => PlayerSlotLib.Slot) slots;
    }

    struct CoinStorage {
        uint256 goldCount;
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct ArenaStorage {
        uint256 basicArenaCounter;
        mapping(uint256 => BasicArena) basicArenas;
        mapping(uint256 => mapping(uint256 => uint256)) basicArenaCooldowns;
        uint256 hillArenaCounter;
        mapping(uint256 => HillArena) hillArenas;
        mapping(uint256 => uint256) hillArenaScores;
        mapping(uint256 => mapping(uint256 => uint256)) hillArenaCooldowns;
        mapping(uint256 => mapping(uint256 => uint256)) hillArenaTime;
        mapping(uint256 => uint256) mainArenaWins;
        mapping(uint256 => uint256) mainArenaLosses;
        mapping(uint256 => uint256) totalArenaWins;
        mapping(uint256 => uint256) totalArenaLosses;
        mapping(uint256 => mapping(uint256 => uint256)) basicAreanaWins;
        mapping(uint256 => mapping(uint256 => uint256)) hillAreanaWins;

    }


////////// Sorage Functions ///////////////////////////////////////////////////////////////////////////////////////

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
    function diamondStorageArena() internal pure returns (ArenaStorage storage ds) {
        bytes32 position = ARENA_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

////////// Create Arena Functions ///////////////////////////////////////////////////////////////////////////////////////

    function _createBasicArena(uint256 _cost, uint256 _cooldown, string memory _name, string memory _uri) internal {
        ArenaStorage storage a = diamondStorageArena();
        a.basicArenaCounter++; // incmrement counter
        a.basicArenas[a.basicArenaCounter] = BasicArena(
            a.basicArenaCounter,
            _cost,
            _cooldown,
            0, //hostId starts at zero to show that there is no player
            true, //arena is open (nobody is currently here)
            payable(msg.sender),
            _name,
            _uri
        );
    }

    function _createHillArena(uint256 _cost, uint256 _cooldown, string memory _name, string memory _uri) internal {
        ArenaStorage storage a = diamondStorageArena();
        a.hillArenaCounter++; // incmrement counter
        a.hillArenas[a.hillArenaCounter] = HillArena(
            a.hillArenaCounter,
            _cost,
            _cooldown,
            0, //hostId starts at zero to show that there is no player
            true, //arena is open (nobody is currently here)
            payable(msg.sender),
            _name,
            _uri
        );
    }


////////// Enter Arena Functions ///////////////////////////////////////////////////////////////////////////////////////    

    function _enterBasicArena(uint256 _playerId, uint256 _basicArenaId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        BasicArena storage arena = a.basicArenas[_basicArenaId]; //save arena object
        require(arena.open, "arena is not open"); //arena is open
        uint256 timer;
        s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
        require(block.timestamp >= a.basicArenaCooldowns[_basicArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
        require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
        c.goldBalance[msg.sender] -= arena.cost; //deduct one gold from their balance
        s.players[_playerId].status = 4; //set the host's status to being in the arena
        a.basicArenas[_basicArenaId].open = false; //close the arena
        a.basicArenas[_basicArenaId].hostId = _playerId;
        a.basicArenas[_basicArenaId].hostAddress = payable(msg.sender);
    }

    function _enterHillArena(uint256 _playerId, uint256 _hillArenaId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ArenaStorage storage a = diamondStorageArena();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        HillArena storage arena = a.hillArenas[_hillArenaId]; //save arena object
        require(arena.open, "arena is not open"); //arena is open
        require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
        c.goldBalance[msg.sender] -= arena.cost; //deduct one gold from their balance
        uint256 timer;
        s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
        require(block.timestamp >= a.hillArenaCooldowns[_hillArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
        s.players[_playerId].status = 4; //set the host's status to being in the arena
        a.hillArenas[_hillArenaId].open = false; //close the arena
        a.hillArenas[_hillArenaId].hostId = _playerId;
        a.hillArenas[_hillArenaId].hostAddress = payable(msg.sender);
        a.hillArenaTime[_hillArenaId][_playerId] = block.timestamp;
    }


////////// Fight Arena Functions ///////////////////////////////////////////////////////////////////////////////////////    


    function _fightBasicArena(uint256 _playerId, uint256 _basicArenaId) internal returns (uint256, uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        BasicArena storage arena = a.basicArenas[_basicArenaId]; //save arena object
        require(!arena.open, "arena is not open"); //arena is open
        uint256 timer;
        s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
        require(block.timestamp >= a.basicArenaCooldowns[_basicArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
        require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
        uint256 winner = _simulateBasicFight(arena.hostId, _playerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _playerId) { //means the challenger won
            _winner = _playerId;
            _loser = arena.hostId;
            a.totalArenaWins[_playerId]++; //add total wins
            a.totalArenaLosses[arena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += arena.cost; //increase gold
        } else { //means the host won
            _winner = arena.hostId;
            _loser = _playerId;
            a.totalArenaWins[arena.hostId]++; //add total wins
            a.totalArenaLosses[_playerId]++; //add total losses
            c.goldBalance[arena.hostAddress] += arena.cost*2; //increase gold of the host
            c.goldBalance[msg.sender] -= arena.cost; //decrease gold
        }
        a.basicArenaCooldowns[_basicArenaId][_playerId] = block.timestamp;
        a.basicArenaCooldowns[_basicArenaId][arena.hostId] = block.timestamp;
        a.basicArenas[_basicArenaId].open = true; // open the areana
        s.players[arena.hostId].status = 0; // set the host to idle
        return (_winner, _loser);
    }

    function _fightHillArena(uint256 _playerId, uint256 _hillArenaId) internal returns (uint256, uint256, uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        HillArena storage arena = a.hillArenas[_hillArenaId]; //save arena object
        require(!arena.open, "arena is not open"); //arena is open
        uint256 timer;
        s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
        require(block.timestamp >= a.hillArenaCooldowns[_hillArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
        require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
        uint256 winner = _simulateBasicFight(arena.hostId, _playerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _playerId) { //means the challenger won
            _winner = _playerId;
            _loser = arena.hostId;
            a.totalArenaWins[_playerId]++; //add total wins
            a.totalArenaLosses[arena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += arena.cost; //increase gold
            a.hillArenaTime[_hillArenaId][_playerId] = block.timestamp; //set the curernt time as the start point
            a.hillArenaScores[arena.hostId] += (block.timestamp - a.hillArenaTime[_hillArenaId][arena.hostId]); //give host their points
            s.players[arena.hostId].status = 0; // set the host to idle
            a.hillArenas[_hillArenaId].hostId = _playerId;
            a.hillArenas[_hillArenaId].hostAddress = payable(msg.sender);
        } else { //means the host won
            _winner = arena.hostId;
            _loser = _playerId;
            a.totalArenaWins[arena.hostId]++; //add total wins
            a.totalArenaLosses[_playerId]++; //add total losses
            c.goldBalance[arena.hostAddress] += arena.cost*2; //increase gold of the host
            c.goldBalance[msg.sender] -= arena.cost; //decrease gold
        }
        a.hillArenaCooldowns[_hillArenaId][_playerId] = block.timestamp; //reset cooldown for challenger
        a.hillArenaCooldowns[_hillArenaId][arena.hostId] = block.timestamp; //reset cooldown for host
        return (_winner, _loser, a.hillArenaTime[_hillArenaId][_winner]);
    }

    function _simulateBasicFight(uint256 _hostId, uint256 _challengerId) internal returns(uint256) { //helper function
        PlayerStorage storage s = diamondStoragePlayer();
        PlayerSlotLib.Player storage host = s.players[_hostId];
        PlayerSlotLib.Player storage challenger = s.players[_challengerId];
        uint256 cp = _basicRandom(_challengerId, challenger.strength);
        uint256 hp = _basicRandom(_hostId, host.strength);
        if (cp >= host.currentHealth + host.defense) { //no contest
            s.players[_hostId].currentHealth = 0;
        } else {
            if (cp >= host.defense) {
                s.players[_hostId].currentHealth -= (cp - host.defense);
            }
        }
        if (hp >= challenger.currentHealth + challenger.defense) { //no contest
            s.players[_challengerId].currentHealth = 0;
        } else {
            if (hp >= challenger.defense) {
                s.players[_challengerId].currentHealth -= (hp - challenger.defense);
            }
        }
        if (s.players[_challengerId].currentHealth > s.players[_hostId].currentHealth) {
            return (_challengerId);
        } else {
            return (_hostId);
        }
    }


////////////////////////////////// Leave Arena Functions /////////////////////////////////////////////////////////////////////////////////////// 

    function _leaveBasicArena(uint256 _playerId, uint256 _basicArenaId) internal {
        ArenaStorage storage a = diamondStorageArena();
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        require(a.basicArenas[_basicArenaId].hostId == _playerId, "you are not the host"); //plerys is the current host
        require(s.players[_playerId].status == 4, "you are not in the arena"); //check if they are in arena
        require(s.owners[_playerId] == msg.sender); //ownerOf
        a.basicArenas[_basicArenaId].hostId = 0; //reset the id of arena
        a.basicArenas[_basicArenaId].open = true; //reopen the arena
        s.players[_playerId].status = 0; //set satus og host back to idle
        c.goldBalance[msg.sender] += a.basicArenas[_basicArenaId].cost; //increase gold
    }

    function _leaveHillArena(uint256 _playerId, uint256 _hillArenaId) internal {
        ArenaStorage storage a = diamondStorageArena();
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        require(a.hillArenas[_hillArenaId].hostId == _playerId, "you are not the host"); //plerys is the current host
        require(s.players[_playerId].status == 4, "you are not in the arena"); //check if they are in arena
        require(s.owners[_playerId] == msg.sender); //ownerOf
        a.hillArenas[_hillArenaId].hostId = 0; //reset the id of arena
        a.hillArenas[_hillArenaId].open = true; //reopen the arena
        s.players[_playerId].status = 0; //set satus og host back to idle
        c.goldBalance[msg.sender] += a.basicArenas[_hillArenaId].cost; //increase gold
        a.hillArenaScores[_playerId] += (block.timestamp - a.hillArenaTime[_hillArenaId][_playerId]);
    }


////////////////////////////////// Random Arena Functions /////////////////////////////////////////////////////////////////////////////////////// 


    function _random(uint256 _nonce, uint256 _value) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _nonce, _value)));
    }

    function _basicRandom(uint256 _nonce, uint256 _value) internal view  returns (uint256) {
        uint256 random = (_random(_nonce, _value) % 99) + 100;
        return ((_value * random) / 100);
    }


////////// Stake Functions ///////////////////////////////////////////////////////////////////////////////////////


    
////////// View Functions ///////////////////////////////////////////////////////////////////////////////////////

    function _getTotalWins(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.totalArenaWins[_playerId];
    }
    function _getTotalLosses(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.totalArenaLosses[_playerId];
    }

    function _getBasicArena(uint256 _basicArenaId) internal view returns (BasicArena memory) {
        ArenaStorage storage a = diamondStorageArena();
        return a.basicArenas[_basicArenaId];
    }
    function _getHillArena(uint256 _hillArenaId) internal view returns (HillArena memory) {
        ArenaStorage storage a = diamondStorageArena();
        return a.hillArenas[_hillArenaId];
    }

    function _getBasicArenaCount() internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.basicArenaCounter;
    }
    function _getHillArenaCount() internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.hillArenaCounter;
    }

    function _getBasicArenaCooldown(uint256 _playerId, uint256 _basicArenaId) internal view returns (uint256){
        ArenaStorage storage a = diamondStorageArena();
        return a.basicArenaCooldowns[_basicArenaId][_playerId];
    }
    function _getHillArenaCooldown(uint256 _playerId, uint256 _hillArenaId) internal view returns (uint256){
        ArenaStorage storage a = diamondStorageArena();
        return a.hillArenaCooldowns[_hillArenaId][_playerId];
    }

    function _getGoldBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.goldBalance[_address];
    }

    function _getHillArenaScore(uint256 _playerId) internal view returns(uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.hillArenaScores[_playerId];
    }

    function _mintGold() internal {
        CoinStorage storage c = diamondStorageCoin();
        c.goldBalance[msg.sender] += 100;
    }

}

contract ArenaFacet {
    event CreateBasicArena(uint256 _basicArenaId, BasicArena _basicArena);
    event CreateHillArena(uint256 _hillArenaId, HillArena _hillArena);
    event BasicArenaWin(uint256 indexed _playerId, uint256 indexed _basicArenaId);
    event BasicArenaLoss(uint256 indexed _playerId, uint256 indexed _basicArenaId);
    event EnterBasicArena(uint256 indexed _playerId, uint256 indexed _basicArenaId);
    event EnterHillArena(uint256 indexed _playerId, uint256 indexed _hillArenaId, uint256 indexed _timestamp);
    event LeaveBasicArena(uint256 indexed _playerId, uint256 indexed _basicArenaId);

    function createBasicArena(uint256 _cost, uint256 _cooldown, string memory _name, string memory _uri) public {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        StorageLib._createBasicArena(_cost, _cooldown, _name, _uri);
        uint256 id = StorageLib._getBasicArenaCount();
        emit CreateBasicArena(id, getBasicArena(id));
    }

    function createHillArena(uint256 _cost, uint256 _cooldown, string memory _name, string memory _uri) public {
        address createAccount = payable(0x434d36F32AbeD3F7937fE0be88dc1B0eB9381244);
        require(msg.sender == createAccount);
        StorageLib._createHillArena(_cost, _cooldown, _name, _uri);
        uint256 id = StorageLib._getHillArenaCount();
        emit CreateHillArena(id, getHillArena(id));
    }

    function enterBasicArena(uint256 _playerId, uint256 _basicArenaId) public {
        StorageLib._enterBasicArena(_playerId, _basicArenaId);
        emit EnterBasicArena(_playerId, _basicArenaId);
    }
    function enterHillArena(uint256 _playerId, uint256 _hillArenaId) public {
        StorageLib._enterHillArena(_playerId, _hillArenaId);
        emit EnterHillArena(_playerId, _hillArenaId, block.timestamp);
    }

    function fightBaiscArena(uint256 _playerId, uint256 _basicArenaId) public {
        uint256 _winner;
        uint256 _loser;
        (_winner, _loser) = StorageLib._fightBasicArena(_playerId, _basicArenaId);
        emit BasicArenaWin(_winner, _basicArenaId);
        emit BasicArenaLoss(_loser, _basicArenaId);
    }
    function fightHillArena(uint256 _playerId, uint256 _hillArenaId) public {
        uint256 _winner;
        uint256 _loser;
        uint256 _winnerTime;
        (_winner, _loser, _winnerTime) = StorageLib._fightHillArena(_playerId, _hillArenaId);
        emit BasicArenaWin(_winner, _hillArenaId);
        emit BasicArenaLoss(_loser, _hillArenaId);
    }

    function leaveBasicArena(uint256 _playerId, uint256 _basicArenaId) public {
        StorageLib._leaveBasicArena(_playerId, _basicArenaId);
        emit LeaveBasicArena(_playerId, _basicArenaId);
    }
    
    function leaveHillArena(uint256 _playerId, uint256 _basicArenaId) public {
        StorageLib._leaveHillArena(_playerId, _basicArenaId);
        emit LeaveBasicArena(_playerId, _basicArenaId);
    }

    function getBasicArena(uint256 _basicArenaId) public view returns (BasicArena memory) {
        return StorageLib._getBasicArena(_basicArenaId);
    }

    function getHillArena(uint256 _hillArenaId) public view returns (HillArena memory) {
        return StorageLib._getHillArena(_hillArenaId);
    }

    function getTotalWins(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getTotalWins(_playerId);
    }

    function getTotalLosses(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getTotalLosses(_playerId);
    }

    function getBasicArenaCount() public view returns(uint256) {
        return StorageLib._getBasicArenaCount();
    }
    function getHillArenaCount() public view returns(uint256) {
        return StorageLib._getHillArenaCount();
    }

    function getBasicArenaCooldowns(uint256 _playerId, uint256 _basicArenaId) public view returns (uint256) {
        return StorageLib._getBasicArenaCooldown(_playerId, _basicArenaId);
    }
    function getHillArenaCooldowns(uint256 _playerId, uint256 _hillArenaId) public view returns (uint256) {
        return StorageLib._getHillArenaCooldown(_playerId, _hillArenaId);
    }

    function getHillArenaScore(uint256 _playerId) internal view returns(uint256) {
        return StorageLib._getHillArenaScore(_playerId);
    }

    function getGoldBalance(address _address) public view returns (uint256) {
        return StorageLib._getGoldBalance(_address);
    }

    function freeGold() public {
        StorageLib._mintGold();
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}
