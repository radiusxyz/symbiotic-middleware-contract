// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract stETHTest is ERC20 {
    constructor(uint256 initialSupply) ERC20("stETH Test", "stETH") {
        _mint(msg.sender, initialSupply);
    }
}
