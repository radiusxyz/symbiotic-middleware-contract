// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract wBTCTest is ERC20 {
    constructor(uint256 initialSupply) ERC20("wBTC Test", "wBTC") {
        _mint(msg.sender, initialSupply);
    }
}
