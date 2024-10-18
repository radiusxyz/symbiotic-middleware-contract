// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RadiusTestERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("Radius Test ERC20", "RADI") {
        _mint(msg.sender, initialSupply);
    }
}
