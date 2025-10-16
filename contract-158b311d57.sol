// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts@5.4.0/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts@5.4.0/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts@5.4.0/access/Ownable.sol";

contract MagicToken is ERC20, ERC20Pausable, Ownable, ERC20Permit {
    address public treasury;
    uint8 public tax;
    mapping(address => bool) public isFeeExempt;

    event TaxFeeChanged(uint8 oldFee, uint8 newFee);
    event TreasuryChanged(address oldTreasury, address newTreasury);
    event FeeExemptionSet(address account, bool isExempt);

    constructor(address initialOwner, address treasury_, uint8 taxFee_)
        ERC20("MagicToken", "MAGIC")
        Ownable(initialOwner)
        ERC20Permit("MagicToken")
    {
        require(treasury_ != address(0), "Treasury cannot be zero address");
        require(taxFee_ <= 100, "Fee cannot exceed 100%");
        treasury = treasury_;
        tax = taxFee_;
        _mint(initialOwner, 1_000_000_000000000000000000);
    }

    function setTaxFee(uint8 newFee) external onlyOwner {
        require(newFee <= 100, "Fee cannot exceed 100%");
        emit TaxFeeChanged(tax, newFee);
        tax = newFee;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Treasury cannot be zero address");
        emit TreasuryChanged(treasury, newTreasury);
        treasury = newTreasury;
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
        emit FeeExemptionSet(account, exempt);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Pausable)
    {
        if (from != address(0) && to != address(0) && !paused()) {
            if (!isFeeExempt[from] && !isFeeExempt[to] && tax > 0) {
                uint256 fee = (amount * tax) / 100;
                uint256 net = amount - fee;
                super._update(from, treasury, fee);
                super._update(from, to, net);
                return;
            }
        }
        super._update(from, to, amount);
    }
}

