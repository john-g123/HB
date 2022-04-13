// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../base/ERC20.sol";
import "../base/Ownable.sol";
import "../base/IGameEngine.sol";

contract testSUPFactory is ERC20, Ownable {
    GameEngine game;
    constructor(address _gameEngine) ERC20("SUP", "$SUP") {
        _mint(msg.sender, 1000000000 ether);
        game = GameEngine(_gameEngine);
    }

    function setContract(address _gameEngine) external onlyOwner {
        game = GameEngine(_gameEngine);
    }

   function mintFromEngine(address _receiver, uint _amount) external {
       require ( msg.sender == address(game));
       _mint(_receiver, _amount);
   }

    function mint(address to, uint _amount) external {
        _mint(to, _amount);
    }

}