// SPDX-License-Identifier: MIT
// @author: Developed by Pinqode.
// @descpriton: Cities on the blockchain.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cities is ERC20, Ownable {
    constructor() ERC20("Cities", "CTY") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


    uint256 private _totalCities;

    struct City {
        uint256 id;
        address cityOwner;
        uint256 totalGames;
        uint256 fee;
        uint256 minStake;
    }

    City[] private _cities;

    function createCity(uint256 _minStake, uint256 _fee) public {
        _cities.push(
            City({
                id: _totalCities + 1,
                cityOwner: msg.sender,
                totalGames: 0,
                fee: _fee,
                minStake: _minStake
            })
        );

        _totalCities++;
    }

     function getCity(uint256 _cityId) public view returns(City memory) {
         uint256 cityIndex = cityIndexFromId(_cityId);
        return _cities[cityIndex];
    }

    function setCityFee(uint256 _cityId, uint256 _amount) public {
        require(true, "City does not exist"); // city exists
        uint256 cityIndex = cityIndexFromId(_cityId); 

        require(
            msg.sender == _cities[cityIndex].cityOwner,
            "Sender is not city owner"
        ); // is city owner
        _cities[cityIndex].fee = _amount;
    }

    // function sellCity(address _buyer) public {}

    function totalCities() public view returns (uint256) {
        return _totalCities;
    }



    function minStake(uint256 _cityIndex) public view returns (uint256) {
        return _cities[_cityIndex].minStake;
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

    function payCityFee() public {}
   
}
