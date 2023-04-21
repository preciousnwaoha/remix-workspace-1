// SPDX-License-Identifier: MIT
// @author: Developed by Pinqode.
// @descpriton: Patents creator and manager

/* 
TESTING VALUES
    ["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", 
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", 
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Cities.sol";

contract Chaincity is Cities, ReentrancyGuard {
    // The token being sold
    ERC20 public token;
    // Address where funds are collected
    address payable public wallet;

    string private _auth;

    uint256 private _totalCities;
    uint256 private _totalGames;

    struct Player {
        address addr;
        uint256 stake;
        uint256 cash;
        uint256 location;
    }

    struct Game {
        uint256 id;
        uint256 totalPlayers;
        uint256 totalStake;
        mapping(uint256 => Player) players;
        mapping(address => bool) playerExists;
        uint256 startingCash;
        address gameOwner;
        uint256 cash;
        uint256 city;
        bool playing;
        uint256 turn;

    }

    Game[] private _games;

    uint256 private _nonce;

    constructor(address payable _wallet, ERC20 _token) payable {
        require(_wallet != address(0));

        wallet = _wallet;
        token = _token;
    }

    /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {

  }

  /**
   * @dev recieve function ***DO NOT OVERRIDE***
   */
  receive () external payable {}

   // Modifier to check if caller is auth
    modifier isAuth(string memory _inputAuth) {
        require(keccak256(abi.encodePacked(_auth)) == keccak256(abi.encodePacked(_inputAuth)), "Caller is not authenticated");
        _; // Placeholder for the modified function's code
    }

  function getAuth() public onlyOwner returns(string memory ) {
    return _auth;
  }

    function updateAuth(string memory _inputAuth) public onlyOwner {
        _auth = _inputAuth;
    }

    function createGame(uint256 _cityId, uint256 _startingCash) public returns (uint256) {
        uint256 cityIndex = cityIndexFromId(_cityId);
        address gameOwner = _cities[cityIndex].cityOwner;
       
        _games.push();
        Game storage game = _games[_totalGames];
        game.id = _totalGames + 1;
        game.totalPlayers = 0;
        game.totalStake = 0;
        game.startingCash = _startingCash;
        game.gameOwner = gameOwner;
        game.cash = 0;
        game.city = _cityId;
        game.totalStake = 0;
        game.playing = false;
        game.turn = 1;

        _totalGames++;

        return _totalGames;
    }

    function totalGames() public view returns (uint256) {
        return _totalGames;
    }

    
    function getGame(uint256 _gameId) external view returns (
        uint256 id, uint256 totalPlayers, 
        uint256 totalStake, uint256 startingCash, 
        address gameOwner, uint256 city, 
        uint256 cash, bool playing ) {

        Game storage game = _games[_gameId - 1];
        id = game.id;
        totalPlayers = game.totalPlayers;
        startingCash = game.startingCash;
        gameOwner = game.gameOwner;
        cash = game.cash;
        city = game.city;
        totalStake = game.totalStake;
        playing = game.playing;
    }


    function addPlayer(uint256 _cityId, uint256 _gameId) public payable {
        uint256 cityIndex = cityIndexFromId(_cityId);
        uint256 gameIndex = gameIndexFromId(_gameId);
        Game storage game = _games[gameIndex];
        
        require(game.playing == false, "game already started");
        require(game.playerExists[msg.sender] == false, "player already exists");
        require(msg.value >= _cities[cityIndex].minStake, "not enough stake");

        // Add player to the game
        uint256 totalPlayers = game.totalPlayers;
        game.players[totalPlayers + 1] = Player({
            addr: msg.sender,
            stake: msg.value,
            cash: game.startingCash,
            location: 1
        });
        game.playerExists[msg.sender] = true;
        game.totalPlayers++;
        game.totalStake += msg.value;

        // Transfer tokens from player to the contract
        // require(token.transferFrom(msg.sender, address(this), msg.value), "transfer failed");

        // Stake tokens
        if (payable(msg.sender) != wallet) {
            _stake();
        }

        game.cash += msg.value;
        
    }


    function _stake() private {
        uint256 weiAmount = msg.value;
        require(msg.sender != address(0), "_beneficiary is not an address");
        require(weiAmount >= 0, "_weiAmount is less than or 0");
        wallet.transfer(msg.value);
        // payable(msg.sender).transfer(bonus);
    }

    function getPlayers( uint256 _gameId) public view returns (Player[] memory)  {
        // require(cityExists(cityId), "City does not exist");
        // require(gameExists(_gameId), "Game does not exist");
        // require(isPlaying(_gameId), "Game is not playing");

        uint256 gameIndex = gameIndexFromId(_gameId);

        Player[] memory players_ = new Player[](_games[gameIndex].totalPlayers);
        for (uint256 i = 1; i <= _games[gameIndex].totalPlayers; i++) {
           players_[i-1] = _games[gameIndex].players[i];
        }

        return players_;
    }

    // function play(uint256 _gameId) public {
    //     uint256 gameIndex = gameIndexFromId(_gameId);
    //     Game storage game = _games[gameIndex];
    //     require(game.playerExists[msg.sender] == true, "Player does not exist");
    //     require(game.players[game.turn].addr == msg.sender, "Not from turn");

    //     uint256 play1 = _random(1, 6);
    //     uint256 play2 = _random(1, 6);

    //     // role1, move1, pay1, next1 
    // }

    // move player
    // function _movePlayer() internal {

    // }

    // function _random(uint256 a, uint256 b) internal returns (uint256) {
    //     uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce))) % b;
    //     randomnumber = randomnumber + a;
    //     _nonce++;
    //     return randomnumber;
    // }

    // function payPlayer(
    //     uint256 _gameId,
    //     address _to,
    //     address _from,
    //     uint256 _cash
    // ) public {

    //     require(_to != address(0), "Invalid 'to' address");
    //     require(_from != address(0), "Invalid 'from' address");

    //     uint256 gameIndex = gameIndexFromId(_gameId);
    //     // Game storage game = _games[gameIndex]
    //     // require(game.players[game.turn].addr == _from, "Not from turn")
    //     uint256 indexOfTo;
    //     uint256 indexOfFrom;
    //     for (uint256 i = 1; i <= _games[gameIndex].totalPlayers; i++) {
    //         address playerAddr = _games[gameIndex].players[i].addr;
    //         if (playerAddr == _to) {
    //             indexOfTo = i;
    //         }
    //         if (playerAddr == _from) {
    //             indexOfFrom = i;
    //         }
    //     }

    //     // if (_games[gameIndex].gameOwner == _to) { // game owner is recieving
    //     //     _games[gameIndex].players[indexOfFrom].cash -= _cash;
    //     //     _games[gameIndex].cash += _cash;
    //     // } else if (_games[gameIndex].gameOwner == _from) { // game owner is sending
    //     //     _games[gameIndex].cash -= _cash;
    //     //     _games[gameIndex].players[indexOfTo].cash += _cash;
    //     // } else {
    //         _games[gameIndex].players[indexOfFrom].cash -= _cash;
    //         _games[gameIndex].players[indexOfTo].cash += _cash;
    //     // }
    // }


    function startGame(
        uint256 _gameId
    ) public  {
        uint256 gameIndex = gameIndexFromId(_gameId);
        
        Game storage game = _games[gameIndex];
        require(game.playing == false, "Game already started");

        uint256 totalPlayers = game.totalPlayers;
        require(totalPlayers > 0, "No players in game");
        require(totalPlayers >= 2, "Not enough players (>=2)");

        uint256 totalStake = game.totalStake;
    require(totalStake > 0, "No stake in game");

        // for (uint256 i = 1; i <= totalPlayers; i++) {
        //     Player storage player = game.players[i];
        //     // token.transferFrom(player.addr, address(this), player.stake);
        // }

        game.playing = true;
    }




    function endGame(uint256 gameIndex) public {
        // 
        _cashoutAll(gameIndex);

        _deleteGame(gameIndex);
    }


    function _cashoutAll(uint256 _gameId) internal {
        // games has ended
        // 
        uint256 gameIndex = gameIndexFromId(_gameId);
        for (uint256 i = 0; i < _games[gameIndex].totalPlayers; i++) {
            address playerAddr = _games[gameIndex].players[i].addr;
            uint256 playerStake = _games[gameIndex].players[i].stake;
            uint256 playerCash = _games[gameIndex].players[i].cash;

            uint256 playerReturn = _calculatePlayerReturn(
                playerStake,
                playerCash,
                _games[gameIndex].startingCash
            );

            _processPayout(playerAddr, playerReturn);
        }
    }

    function gameIndexFromId(uint256 _gameId) public view returns (uint256) {
        require(_games.length >= 0, "No games");
        require((_gameId <= _games.length) && (_gameId >= 0), "No such Id");

        for (uint256 i = 0; i < _games.length; i++) {
            if (_games[i].id == _gameId) {
                return i;
            }
        }

        // If no match was found in the loop, return an error message
        revert("Game ID not found");
    }


   
   
    function _calculatePlayerReturn(
        uint256 _playerStake,
        uint256 _playerCash,
        uint256 _startingCash
    ) internal pure returns (uint256) {
        return (_playerCash / _startingCash) * _playerStake;
    }

    function _deleteGame(uint256 _gameId) internal {
        uint256 len = _totalGames;
        uint256 gameIndex = gameIndexFromId(_gameId);
        require(gameIndex < len, "Invalid game index");

        for (uint256 i = gameIndex; i < len - 1; i++) {
            Game storage game = _games[i + 1];
            game = game;
        }
        _games.pop();
        _totalGames--;
    }

    

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        pure
    {
        require(_beneficiary != address(0), "_beneficiary is not an address");
        require(_weiAmount != 0, "_weiAmount is 0");
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    function _processPayout(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
