// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "../libraries/PlayerSlotLib.sol";
// import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";

// struct BasicArena {
//     uint256 basicArenaId;
//     uint256 cost;
//     uint256 cooldown;
//     uint256 hostId;
//     bool open;
//     address payable hostAddress;
//     string name;
//     string url;
// }

// library StorageLib {
//     bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
//     bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
//     bytes32 constant ARENA_STORAGE_POSITION = keccak256("Arena.test.storage.a");

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
//         mapping(uint256 => PlayerSlotLib.Slot) slots;
//     }

//     struct CoinStorage {
//         mapping(address => uint256) goldBalance;
//         mapping(address => uint256) totemBalance;
//         mapping(address => uint256) diamondBalance;
//     }

//     struct ArenaStorage {
//         uint256 basicArenaCounter;
//         mapping(uint256 => BasicArena) basicArenas;
//         mapping(uint256 => mapping(uint256 => uint256)) basicArenaCooldowns;

//         mapping(uint256 => uint256) mainArenaWins;
//         mapping(uint256 => uint256) mainArenaLosses;
//         mapping(uint256 => uint256) secondArenaWins;
//         mapping(uint256 => uint256) secondArenaLosses;
//         mapping(uint256 => uint256) thirdArenaWins;
//         mapping(uint256 => uint256) thirdArenaLosses;
//         mapping(uint256 => uint256) magicArenaWins;
//         mapping(uint256 => uint256) magicArenaLosses;
//         mapping(uint256 => uint256) totalArenaWins;
//         mapping(uint256 => uint256) totalArenaLosses;
//     }



// ////////// Sorage Functions ///////////////////////////////////////////////////////////////////////////////////////

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
//     function diamondStorageArena() internal pure returns (ArenaStorage storage ds) {
//         bytes32 position = ARENA_STORAGE_POSITION;
//         assembly {
//             ds.slot := position
//         }
//     }

// ////////// Sorage Functions ///////////////////////////////////////////////////////////////////////////////////////

//     function _createBasicArena(uint256 _cost, uint256 _cooldown, string memory _name, string memory _uri) internal {
//         ArenaStorage storage a = diamondStorageArena();
//         a.basicArenaCounter++; // incmrement counter
//         a.basicArenas[a.basicArenaCounter] = BasicArena(
//             a.basicArenaCounter,
//             _cost,
//             _cooldown,
//             0, //hostId starts at zero to show that there is no player
//             true, //arena is open (nobody is currently here)
//             payable(msg.sender),
//             _name,
//             _uri
//         );
//     }

//     function _enterBasicArena(uint256 _playerId, uint256 _basicArenaId) internal {
//         PlayerStorage storage s = diamondStoragePlayer();
//         CoinStorage storage c = diamondStorageCoin();
//         ArenaStorage storage a = diamondStorageArena();
//         require(s.players[_playerId].status == 0); //make sure player is idle
//         require(s.owners[_playerId] == msg.sender); //ownerOf
//         BasicArena storage arena = a.basicArenas[_basicArenaId]; //save arena object
//         require(arena.open, "arena is not open"); //arena is open
//         uint256 timer;
//         s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
//         require(block.timestamp >= a.basicArenaCooldowns[_basicArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
//         require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
//         c.goldBalance[msg.sender] -= arena.cost; //deduct one gold from their balance
//         s.players[_playerId].status = 4; //set the host's status to being in the arena
//         a.basicArenas[_basicArenaId].open = false; //close the arena
//         a.basicArenas[_basicArenaId].hostId = _playerId;
//         a.basicArenas[_basicArenaId].hostAddress = payable(msg.sender);
//     }

//     function _fightBasicArena(uint256 _playerId, uint256 _basicArenaId) internal returns (uint256, uint256) {
//         PlayerStorage storage s = diamondStoragePlayer();
//         CoinStorage storage c = diamondStorageCoin();
//         ArenaStorage storage a = diamondStorageArena();
//         require(s.players[_playerId].status == 0); //make sure player is idle
//         require(s.owners[_playerId] == msg.sender); //ownerOf
//         BasicArena storage arena = a.basicArenas[_basicArenaId]; //save arena object
//         require(!arena.open, "arena is not open"); //arena is open
//         uint256 timer;
//         s.players[_playerId].agility >= arena.cooldown/2  ? timer = arena.cooldown/2 : timer = arena.cooldown/2 - s.players[_playerId].agility + 10;
//         require(block.timestamp >= a.basicArenaCooldowns[_basicArenaId][_playerId] + timer); //make sure that they have waited 5 mins since last quest (600 seconds);
//         require(c.goldBalance[msg.sender] >= arena.cost, "broke ass got no money"); //gold check
//         uint256 winner = _simulateBasicFight(arena.hostId, _playerId);
//         uint256 _winner;
//         uint256 _loser;
//         if (winner == _playerId) { //means the challenger won
//             _winner = _playerId;
//             _loser = arena.hostId;
//             a.totalArenaWins[_playerId]++; //add total wins
//             a.totalArenaLosses[arena.hostId]++; //add total losses
//             c.goldBalance[msg.sender] += arena.cost; //increase gold
//         } else { //means the host won
//             _winner = arena.hostId;
//             _loser = _playerId;
//             a.totalArenaWins[arena.hostId]++; //add total wins
//             a.totalArenaLosses[_playerId]++; //add total losses
//             c.goldBalance[arena.hostAddress] += arena.cost*2; //increase gold of the host
//             c.goldBalance[msg.sender] -= arena.cost; //decrease gold
//         }
//         a.basicArenas[_basicArenaId].open = true; // open the areana
//         s.players[arena.hostId].status = 0; // set the host to idle
//         return (_winner, _loser);
//     }

//     function _simulateBasicFight(uint256 _hostId, uint256 _challengerId) internal returns(uint256) { //helper function
//         PlayerStorage storage s = diamondStoragePlayer();
//         PlayerSlotLib.Player storage host = s.players[_hostId];
//         PlayerSlotLib.Player storage challenger = s.players[_challengerId];
//         challenger.strength * _random(_challengerId) >= host.currentHealth + host.defense ?
//             s.players[_hostId].currentHealth = 0 
//             : 
//             s.players[_hostId].currentHealth = host.currentHealth + host.defense - challenger.strength;
//         host.strength * _random(_hostId) >= challenger.currentHealth + challenger.defense ?
//             s.players[_challengerId].currentHealth = 0 
//             : 
//             s.players[_challengerId].currentHealth = challenger.currentHealth + challenger.defense - host.strength;
//         if (s.players[_challengerId].currentHealth > s.players[_hostId].currentHealth) {
//             return (_challengerId);
//         } else {
//             return (_hostId);
//         }
//     }


//     function _random(uint256 nonce) internal returns (uint256) {
//         return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, nonce)));
//     }


//     function _getTotalWins(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.totalArenaWins[_playerId];
//     }

//     function _getMainArenaWins(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.mainArenaWins[_playerId];
//     }

//     function _getMagicArenaWins(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.magicArenaWins[_playerId];
//     }

//     function _getTotalLosses(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.totalArenaLosses[_playerId];
//     }

//     function _getMainArenaLosses(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.mainArenaLosses[_playerId];
//     }

//     function _getMagicArenaLosses(uint256 _playerId) internal view returns (uint256) {
//         ArenaStorage storage a = diamondStorageArena();
//         return a.magicArenaLosses[_playerId];
//     }

//     function _leaveMainArena(uint256 _hostId) internal {
//         ArenaStorage storage a = diamondStorageArena();
//         PlayerStorage storage s = diamondStoragePlayer();
//         CoinStorage storage c = diamondStorageCoin();
//         require(a.mainArena.hostId == _hostId, "you are not the host"); //plerys is the current host
//         require(s.players[_hostId].status == 4, "you are not in the arena"); //check if they are in arena
//         a.mainArena.hostId = 0; //reset the id of arena
//         a.mainArena.open = true; //reopen the arena
//         s.players[_hostId].status = 0; //set satus og host back to idle
//         c.goldBalance[msg.sender] += 1; //increase gold
//     }

//     function _openArenas() internal {
//         ArenaStorage storage a = diamondStorageArena();
//         // require(a.open == false);
//         // a.open = true;
//         a.mainArena.open = true;
//         // a.secondArena.open = true;
//         // a.thirdArena.open = true;
//         // a.magicArena.open = true;
//     }

//     function _getPlayerAddress(uint256 _id) internal view returns (address player) {
//         PlayerStorage storage s = diamondStoragePlayer();
//         player = s.owners[_id];
//     }
// }

// contract ArenaFacet {
//     event MainWin(uint256 indexed _playerId);
//     event SecondWin(uint256 indexed _playerId);
//     event MagicWin(uint256 indexed _playerId);
//     event MainLoss(uint256 indexed _playerId);
//     event SecondLoss(uint256 indexed _playerId);
//     event MagicLoss(uint256 indexed _playerId);

//     event EnterMain(uint256 indexed _playerId);
//     event EnterSecond(uint256 indexed _playerId);
//     event EnterMagic(uint256 indexed _playerId);

//     function openArenas() public {
//         StorageLib._openArenas();
//     }

//     function getMainArena() external view returns (bool, uint256) {
//         return StorageLib._getMainArena();
//     }

//     function getSecondArena() external view returns (bool, uint256) {
//         return StorageLib._getSecondArena();
//     }
//     // function getThirdArena() external view returns(bool) {
//     //     return StorageLib._getMainArena();
//     // }

//     function getMagicArena() external view returns (bool, uint256) {
//         return StorageLib._getMagicArena();
//     }

//     function enterMainArena(uint256 _playerId) public {
//         StorageLib._enterMainArena(_playerId);
//         emit EnterMain(_playerId);
//     }

//     function fightMainArena(uint256 _challengerId) public {
//         uint256 _winner;
//         uint256 _loser;
//         (_winner, _loser) = StorageLib._fightMainArena(_challengerId);
//         emit MainWin(_winner);
//         emit MainLoss(_loser);
//     }

//     function enterSecondArena(uint256 _playerId) public {
//         StorageLib._enterSecondArena(_playerId);
//         emit EnterSecond(_playerId);
//     }

//     function fightSecondArena(uint256 _challengerId) public {
//         uint256 _winner;
//         uint256 _loser;
//         (_winner, _loser) = StorageLib._fightSecondArena(_challengerId);
//         emit SecondWin(_winner);
//         emit SecondLoss(_loser);
//     }

//     function enterMagicArena(uint256 _playerId) public {
//         StorageLib._enterMagicArena(_playerId);
//         emit EnterMagic(_playerId);
//     }

//     function fightMagicArena(uint256 _challengerId) public {
//         uint256 _winner;
//         uint256 _loser;
//         (_winner, _loser) = StorageLib._fightMagicArena(_challengerId);
//         emit MagicWin(_winner);
//         emit MagicLoss(_loser);
//     }

//     function leaveMainArena(uint256 _playerId) public {
//         StorageLib._leaveMainArena(_playerId);
//     }

//     function getTotalWins(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getTotalWins(_playerId);
//     }

//     function getMagicArenaWins(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getMagicArenaWins(_playerId);
//     }

//     function getMainArenaWins(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getMainArenaWins(_playerId);
//     }

//     function getTotalLosses(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getTotalLosses(_playerId);
//     }

//     function getMagicArenaLosses(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getMagicArenaLosses(_playerId);
//     }

//     function getMainArenaLosses(uint256 _playerId) public view returns (uint256) {
//         return StorageLib._getMainArenaLosses(_playerId);
//     }

//     //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
// }
