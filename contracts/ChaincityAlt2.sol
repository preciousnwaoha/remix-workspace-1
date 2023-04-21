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
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CitiesAlt.sol";

contract Chaincity is Cities {
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

    }

    Game[] private _games;

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

   /**
     * MODIFIERS
     */

    // Modifier to check if caller is auth
    modifier isAuth(string memory _inputAuth) {
        require(
            keccak256(abi.encodePacked(_auth)) ==
                keccak256(abi.encodePacked(_inputAuth)),
            "Caller is not authenticated"
        );
        _;
    }

    modifier gameExists(uint256 _gameId) {
        require(_gameId > 0, "Game ID not valid!");
        require(_gameId <= _games.length, "Game ID not valid!");
        _;
    }

    modifier gameStarted(uint256 _gameId) {
        require(_games[_gameId - 1].playing == true, "game not started");
        _;
    }

    modifier gameNotStarted(uint256 _gameId) {
        require(_games[_gameId - 1].playing != true, "game already started");
        _;
    }


    function getAuth() public view onlyOwner returns (string memory) {
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

        _totalGames++;

        return _totalGames;
    }

    function totalGames() public view returns (uint256) {
        return _totalGames;
    }

    
    function getGame(uint256 _gameId, string memory _inputAuth)
        external
        view
        gameExists(_gameId)
        isAuth(_inputAuth) 
        returns (
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


    function addPlayer(uint256 _cityId, uint256 _gameId) public 
    payable
        cityExists(_cityId)
        gameExists(_gameId)
        gameNotStarted(_gameId)
    {
        uint256 cityIndex = _cityId - 1;
        uint256 gameIndex = _gameId - 1;
        Game storage game = _games[gameIndex];

        require(game.playerExists[msg.sender] == false, "player already exists");
        require(msg.value >= _cities[cityIndex].minStake, "not enough stake");

        // Add player to the game
        uint256 totalPlayers = game.totalPlayers;
        game.players[totalPlayers + 1] = Player({
            addr: msg.sender,
            stake: msg.value
        });
        game.playerExists[msg.sender] = true;
        game.totalPlayers++;
        game.totalStake += msg.value;

        // Stake tokens
        if (payable(msg.sender) != wallet) {
            _stake();
        }

        game.cash += msg.value;
    }

    function getPlayers(uint256 _gameId)
        public
        view
        gameExists(_gameId)
        gameStarted(_gameId)
        returns (Player[] memory)
    {
        uint256 gameIndex = gameIndexFromId(_gameId);

        Player[] memory players_ = new Player[](_games[gameIndex].totalPlayers);
        for (uint256 i = 1; i <= _games[gameIndex].totalPlayers; i++) {
            players_[i - 1] = _games[gameIndex].players[i];
        }

        return players_;
    }

    function startGame(uint256 _gameId)
        public
        gameExists(_gameId)
        gameNotStarted(_gameId)
    {
        Game storage game = _games[_gameId - 1];

        uint256 totalPlayers = game.totalPlayers;
        require(totalPlayers > 0, "No players in game");
        require(totalPlayers >= 2, "Not enough players (>=2)");

        uint256 totalStake = game.totalStake;
        require(totalStake > 0, "No stake in game");

        game.playing = true;
    }

   
    function endGame(
        uint256 _gameId,
        address[] memory _winAddrOrder,
        uint256 _winCash,
        string memory _inputAuth
    ) public
        isAuth(_inputAuth)
        gameExists(_gameId) 
        gameStarted(_gameId) {
        uint256 gameIndex = _gameId - 1;
        Game storage game = _games[gameIndex];
        require(
            _winAddrOrder.length == game.totalPlayers,
            "Invalid No of Players Cash"
        );

        for (uint i = 0; i < _winAddrOrder.length; i++) {
            require(game.playerExists[_winAddrOrder[i]], "Player does not exist!");
        }


        _cashoutAll(gameIndex, _winCash, _winAddrOrder);

        _deleteGame(gameIndex);
    }

    
    function gameIndexFromId(uint256 _gameId)
    public view
    gameExists(_gameId) 
    returns (uint256) {
        return _gameId - 1;
    }

function _stake() private {
        uint256 tokenAmount = msg.value;
        require(tokenAmount >= 0, "_tokenAmount is less than or 0");

        bool success = token.transfer(wallet, tokenAmount);

        // Check if the transfer was successful
        require(success, "Token transfer failed");
    }

    /**
     * INTERNAL FUNCTIONS
     */

    function _cashoutAll(
        uint256 _gameId, 
        uint256 _winCash, 
        address[] memory _winAddrOrder) internal 
        gameExists(_gameId) {
            
            Game storage game = _games[_gameId - 1];

            uint256 totalCash = (game.startingCash * game.totalPlayers);
            uint256 winnerStake = game.players[0].stake;
            uint256 winnerPercentStake = winnerStake / game.totalStake;
            uint256 winnerCashGain = _winCash - game.startingCash;
            uint256 WCG2Stake = winnerCashGain * winnerStake / game.startingCash;
            uint256 oneCashValue = (totalCash / game.totalStake);

            if ((WCG2Stake + winnerStake) <= game.totalStake) {
                uint256 winnerStakeReturn = (WCG2Stake + winnerStake);
                uint256 stakeLeft = game.totalStake - (WCG2Stake + winnerStake);
                uint256 winnerTokenReturn = stakeLeft * winnerPercentStake;
                _payout(msg.sender, winnerStakeReturn, winnerTokenReturn );

                for (uint256 i = 1; i < _winAddrOrder.length; i++) {
                    uint256 playerStake = game.players[i].stake;
                    uint256 playerPercentStake = playerStake / game.totalStake;
                    uint256 playerStakeReturn = (stakeLeft * playerPercentStake) / 2;
                    uint256 playerTokenReturn = playerStakeReturn * oneCashValue;

                    _payout(msg.sender, playerStakeReturn, playerTokenReturn );
                }

                
            } else {
                uint256 winnerStakeReturn = game.totalStake;
                uint256 stakeLeft = (WCG2Stake + winnerStake) - winnerStakeReturn;

                uint256 winnerTokenReturn = (stakeLeft * winnerPercentStake) * oneCashValue;
                _payout(msg.sender, winnerStakeReturn, winnerTokenReturn );

                for (uint256 i = 1; i < _winAddrOrder.length; i++) {
                    uint256 playerStake = game.players[i].stake;
                    uint256 playerPercentStake = playerStake / game.totalStake;
                    uint256 playerTokenReturn = (stakeLeft * playerPercentStake) * oneCashValue;

                    _payout(msg.sender, 0, playerTokenReturn );
                }

            }

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

    function _payout(address _playerAddr, uint256 _stakeReturn, uint256 _tokenReturn) internal {
        // Check if the smart contract has enough allowance to transfer tokens on behalf of the sender
        require(
            token.allowance(wallet, address(this)) >= _tokenReturn,
            "Insufficient allowance"
        );

    

        // Transfer tokens from the sender to the recipient
        require(
            token.transferFrom(wallet, _playerAddr, _tokenReturn),
            "Token transfer failed"
        );

        if (_stakeReturn > 0) {
            wallet.transfer(_stakeReturn);
        }
    }

    /**
     * @dev Determines how game tokens is stored/forwarded on stakes/cashouts.
     */
    function _forwardFunds() internal {
        token.transferFrom(wallet, msg.sender, msg.value);
    }
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
