// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLUCKToken is ERC20, Ownable {
    mapping(address => bool) public minted;

    constructor() ERC20("BLUCK", "BLK") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Initial supply to contract owner
    }

    function faucet() external {
        require(!minted[msg.sender], "Faucet can only be used once per address");
        minted[msg.sender] = true;
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        _approve(to, msg.sender, amount); // Set allowance for the minter
    }
}
