// SPDX-License-Identifier: MIT
// @author: Developed by Pinqode and Greyshaws.
// @descpriton: Patents creator and manager

/* 
TESTING VALUES
    [["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", 1500, 100], 
["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", 1500, 100], 
    ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", 1500, 50]]

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chaincity is ReentrancyGuard, Ownable {
    // The token being sold
    ERC20 public token;
    // Address where funds are collected
    address payable public wallet;

    uint256 private _totalCities;
    uint256 private _totalGames;

    struct Player {
        address addr;
        uint256 stake;
        uint256 cash;
    }

    struct Game {
        uint256 id;
        uint256 totalPlayers;
        uint256 totalStake;
        mapping(uint256 => Player) players;
        uint256 startingCash;
        address gameOwner;
        uint256 cash;
        uint256 city;
    }

    struct City {
        uint256 id;
        address cityOwner;
        uint256 totalGames;
        uint256 fee;
    }

    Game[] private _games;
    City[] private _cities;

    constructor(address payable _wallet, ERC20 _token) {
        require(_wallet != address(0));

        wallet = _wallet;
        token = _token;
    }

    function createCity() public {
        _cities.push(
            City({
                id: _totalCities + 1,
                cityOwner: msg.sender,
                totalGames: 0,
                fee: 0
            })
        );

        _totalCities++;
    }

    // function payCityFee() public {}

    function setCityFee(uint256 _cityId, uint256 _amount) public {
        require(true, "City does not exist"); // city exists
        uint256 cityIndex = cityIndexFromId(_cityId); // is city owner

        require(
            msg.sender == _cities[cityIndex].cityOwner,
            "Sender is not city owner"
        );
        _cities[cityIndex].fee = _amount;
    }

    // function sellCity(address _buyer) public {}

    function totlaCities() public view returns (uint256) {
        return _totalCities;
    }

    function totalGames() public view returns (uint256) {
        return _totalGames;
    }

    /**
     * GAME PLAY
     */

    function startGame(
        uint256 _cityId,
        address[] memory _players,
        uint256 _startingCash
    ) public payable returns (uint256) {
        uint256 totalPlayers = _players.length;
        uint256 totalStake = 0;
        uint256 cityIndex = cityIndexFromId(_cityId);
        address gameOwner = _cities[cityIndex].cityOwner;
       
        _games.push();
        Game storage game = _games[_totalGames];

        game.id = _totalGames + 1;
        game.totalPlayers = totalPlayers;
        game.totalStake = totalStake;
        game.startingCash = _startingCash;
        game.gameOwner = gameOwner;
        game.cash = 0;
        game.city = _cityId;

        for (uint256 i = 0; i < totalPlayers; i++) {
            game.players[i] = Player({
                addr: _players[i],
                stake: msg.value,
                cash: _startingCash
            });
 
            totalStake += msg.value;

            if (_players[i] != wallet) {
                _stake(_players[i]);
            }
        }

        game.totalStake = totalStake;
        _totalGames++;

        // _games.push(game);

        return _totalGames;
    }

    function endGame(uint256 _gameId) public {
        _cashoutAll(_gameId);

        _deleteGame(_gameId);
    }

    function payPlayer(
        uint256 _gameId,
        address _to,
        address _from,
        uint256 _cash
    ) public {
        require(_to != address(0), "Invalid 'to' address");
        require(_from != address(0), "Invalid 'from' address");

        uint256 gameIndex = gameIndexFromId(_gameId);
        uint256 indexOfTo;
        uint256 indexOfFrom;
        for (uint256 i = 0; i < _games[gameIndex].totalPlayers; i++) {
            address playerAddr = _games[gameIndex].players[i].addr;
            if (playerAddr == _to) {
                indexOfTo = i;
            }
            if (playerAddr == _from) {
                indexOfFrom = i;
            }
        }

        if (_games[gameIndex].gameOwner == _to) {
            _games[gameIndex].players[indexOfFrom].cash -= _cash;
            _games[gameIndex].cash += _cash;
        } else if (_games[gameIndex].gameOwner == _from) {
            _games[gameIndex].cash -= _cash;
            _games[gameIndex].players[indexOfTo].cash += _cash;
        } else {
            _games[gameIndex].players[indexOfFrom].cash -= _cash;
            _games[gameIndex].players[indexOfTo].cash += _cash;
        }
    }

    function _cashoutAll(uint256 _gameId) internal {
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

    function cityIndexFromId(uint256 _cityId) public view returns (uint256) {
        require(_cities.length >= 0, "No cities");
        require((_cityId <= _cities.length) && (_cityId >= 0), "No such Id");

        for (uint256 i = 0; i < _cities.length; i++) {
            if (_cities[i].id == _cityId) {
                return i;
            }
        }

        // If no match was found in the loop, return an error message
        revert("City ID not found");
    }

    // function getPlayersInGame(uint256 _gameId) public returns (Player[] memory) {
    //     uint256 gameIndex = gameIndexFromId(_gameId);
    //     Player[] storage players;
    //     for (uint256 i = 0; i < _games[gameIndex].totalPlayers; i++) {
    //         players.push(_games[gameIndex].players[i]);
    //     }
    //     return players;
    // }

    function getCity(uint256 _cityIndex) public view returns(City memory) {
        return _cities[_cityIndex];
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

    function _stake(address _player) private {
         uint256 weiAmount = msg.value;
        _preValidatePurchase(_player, weiAmount);

        

        _forwardFunds();
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
