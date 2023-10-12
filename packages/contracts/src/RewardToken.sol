// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.8.0 < 0.9.0;

// bare-bones variant.
contract RewardToken is ERC20, Ownable {

    constructor(
        uint supply
    ) ERC20("RewardToken", "RTKN") Ownable(msg.sender) {
        _mint(msg.sender, supply * 1E18);
    }

    function mint(uint amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}