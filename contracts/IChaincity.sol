// SPDX-License-Identifier: MIT
// @author: Developed by Pinqode.
// @descpriton: Interface of Chaincity Game.

pragma solidity ^0.8.0;

// IChaincity defines the interface for the Chaincity contract.
interface IChaincity {
    // Event emitted when a new game is created.
    event GameCreated(
        uint256 indexed gameId,
        uint256 indexed cityId,
        address indexed gameOwner
    );

    // Event emitted when a player joins a game.
    event PlayerJoined(
        uint256 indexed gameId,
        address indexed player,
        uint256 stake
    );

    // Event emitted when a game is started.
    event GameStarted(uint256 indexed gameId);

    // Event emitted when a game is ended and winnings are distributed.
    event GameEnded(uint256 indexed gameId);

    // Event emitted when a player is paid out.
    event PlayerPayout(
        address indexed player,
        uint256 stakeReturn,
        uint256 tokenReturn
    );

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

    // Getter function to retrieve the auth key (only accessible by contract owner).
    function getAuth() external view returns (string memory);

    // Function to update the auth key (only accessible by contract owner).
    function updateAuth(string memory _inputAuth) external;

    // Function to create a new game.
    // Returns the ID of the newly created game.
    function createGame(
        uint256 _cityId,
        uint256 _startingCash,
        string memory _inputAuth
    ) external returns (uint256);

    // Getter function to retrieve the total number of games.
    function totalGames( string memory _inputAuth) external view returns (uint256);

    // Getter function to retrieve information about a specific game.
    function getGame(uint256 _gameId, string memory _inputAuth)
        external
        view
        returns (
            uint256 id,
            uint256 totalPlayers,
            uint256 totalStake,
            uint256 startingCash,
            address gameOwner,
            uint256 city,
            uint256 cash,
            bool playing
        );

    // Function to get the game index from the game ID.
    function gameIndexFromId(uint256 _gameId, string memory _inputAuth) external view returns (uint256);

    // Function to add a player to a game.
    // The player must send the required stake amount as Ether along with the transaction.
    function addPlayer(uint256 _cityId, uint256 _gameId, string memory _inputAuth) external payable;

    // Getter function to retrieve the list of players in a game.
    function getPlayers(uint256 _gameId, string memory _inputAuth) external view returns (Player[] memory);

    // Function to start a game.
    // The game must have at least two players to start.
    function startGame(uint256 _gameId, string memory _inputAuth) external;

    // Function to end a game and distribute winnings to players.
    // The order of winners and the winning cash amount must be provided.
    function endGame(
        uint256 _gameId,
        uint256[] memory _winAddrOrder,
        uint256 _winCash,
        string memory _inputAuth
    ) external payable;

    function getBalance() external view returns (uint256);
}