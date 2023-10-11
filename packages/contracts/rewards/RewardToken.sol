// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity =0.8.19;

// bare-bones variant.
contract RewardToken is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply * 1E18);
    }

    function mint(uint amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}