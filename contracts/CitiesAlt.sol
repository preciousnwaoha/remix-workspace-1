// SPDX-License-Identifier: MIT
// @author: Developed by Pinqode.
// @descpriton: City NFTs

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Properties.sol";

contract Cities is Ownable {
    uint256 private _totalCities;

    struct City {
        uint256 id;
        address cityOwner;
        uint256 totalGames;
        uint256 fee;
        uint256 minStake;
        uint256[] road;
    }

    City[] public _cities;
    mapping(uint256 => address) cityToContract;

    constructor() {
       
    }


    modifier cityExists(uint256 _cityId) {
        require (_cityId > 0, "City ID not valid");
        require(_cityId <= _cities.length, "City ID not valid");
        _;
    } 
    modifier isCityOwner(uint256 _cityId) {
        require(_cities[_cityId - 1].cityOwner == msg.sender, "Not city owner!");
        _;
    }


    function createCity(
        string memory _name, string memory _symbol,
        uint256 _minStake, uint256 _fee, 
        uint256[] memory _road, string[] memory _uris ) 
        public 
        {
        _cities.push(
            City({
                id: _totalCities + 1,
                cityOwner: msg.sender,
                totalGames: 0,
                fee: _fee,
                minStake: _minStake,
                road: _road
            })
        );

        _newProperties(_name, _symbol, _totalCities + 1, _uris);

        _totalCities++;
    }


    function getCity(uint256 _cityId) public view 
        cityExists(_cityId) returns(City memory) {
        return _cities[_cityId - 1];
    }


    function setCityFee(uint256 _cityId, uint256 _amount) public 
    cityExists(_cityId) isCityOwner(_cityId) {
        _cities[_cityId - 1].fee = _amount;
    }

    function totalCities() public view returns (uint256) {
        return _totalCities;
    }

    function minStake(uint256 _cityIndex) public view returns (uint256) {
        return _cities[_cityIndex].minStake;
    }

    function cityIndexFromId(uint256 _cityId)
    public view
    cityExists(_cityId)
    returns (uint256) {
       return _cityId - 1;
    }


    function _newProperties(
        string memory _name, 
        string memory _symbol,
        uint256 _cityId,
        string[] memory _uris
        ) internal {
        Properties newContract = new Properties(_name, _symbol);
        cityToContract[_cityId] = address(newContract);

        for (uint256 i = 0; i < _uris.length; i++) {
            newContract.safeMint(msg.sender, _uris[i]);
        }
    }
}
   

