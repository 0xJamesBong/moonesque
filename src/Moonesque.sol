// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Moonesque is ERC20, Ownable {
    address public treasuryAddress;
    uint256 public burnbips;
    uint256 public taxbips;
    address[] public exemptedAddresses;

    mapping(address => bool) public exempted;

    constructor(
        address _treasuryAddress,
        uint256 _burnbips,
        uint256 _taxbips
    ) ERC20("Moonesque", "MOON") {
        treasuryAddress = _treasuryAddress;
        burnbips = _burnbips;
        taxbips = _taxbips;
    }

    function isExempted(address exemption) public view returns (bool) {
        bool _is = exempted[exemption];
        return _is;
    }

    function allExemptions() public view returns (address[] memory) {
        return exemptedAddresses;
    }

    function configureExemption(
        address exemption
    ) external nonReentrant onlyOwner returns (bool) {
        require(
            exemption != address(0),
            "Trying to add the zero address as exemption!"
        );
        bool _alreadyIsExempted = isExempted(exemption);

        if (!_alreadyIsExempted) {
            exemptedAddresses.push(exemption);
            exempted[exemption] = true;
        }
        return true;
    }

    function removeExemption(
        address exemption
    ) external nonReentrant onlyOwner returns (bool) {
        require(exemption != address(0), "Zero address!");
        require(
            isExempted(exemption),
            "Address not on list of exemption addresses!"
        );
        // deleting value from mapping
        delete exempted[excemption];

        for (uint256 i = 0; i < exemptedAddresses.length; i++) {
            // it replaces it with the last element in the array
            if (exemptedAddresses[i] == exemption) {
                exemptedAddresses[i] = exemptedAddresses[
                    exemptedAddresses.length - 1
                ];
                exemptedAddresses.pop();
                break;
            }
        }
        return true;
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override returns (bool) {
        if (isExempted(msg.sender)) {
            return super.transfer(_to, _value);
        } else {
            uint256 burnAmount = (_value * burnbips) / 10000;
            uint256 taxAmount = (_value * taxbips) / 10000;
            uint256 remainingValue = _value - burnAmount - taxAmount;
            _burn(msg.sender, burnAmount);
            super.transfer(treasuryAddress, taxAmount);
            return super.transfer(_to, remainingValue);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        if (isExempted(msg.sender) || isExempted(_from)) {
            return super.transferFrom(_from, _to, _value);
        } else {
            uint256 burnAmount = (_value * burnbips) / 10000;
            uint256 taxAmount = (_value * taxbips) / 10000;
            uint256 remainingValue = _value - burnAmount - taxAmount;
            _burn(msg.sender, burnAmount);
            super.transfer(treasuryAddress, taxAmount);
            super.transfer(_to, remainingValue);
            return super.transferFrom(_from, _to, _value);
        }
    }
}
