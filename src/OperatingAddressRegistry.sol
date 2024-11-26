// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

abstract contract OperatingAddressRegistry {
    using Checkpoints for Checkpoints.Trace208;

    error DuplicateOperatingAddress();

    mapping(address => Checkpoints.Trace208) private operatorToIdx;
    mapping(address => address) private operatingAddressToOperator;
    mapping(uint208 => address) private idxToOperatingAddress;
    
    uint208 private totalOperatingAddressCount;
    uint208 internal constant EMPTY_OPERATING_ADDRESS_IDX = 0;

    function getOperatorByOperatingAddress(address operatingAddress) public view returns (address) {
        return operatingAddressToOperator[operatingAddress];
    }

    function getCurrentOperatorOperatingAddress(address operator) public view returns (address) {
        uint208 operatingAddressIdx = operatorToIdx[operator].latest();

        if (operatingAddressIdx == EMPTY_OPERATING_ADDRESS_IDX) {
            return address(0);
        }

        return idxToOperatingAddress[operatingAddressIdx];
    }

    function getOperatorOperatingAddressAt(address operator, uint48 timestamp) public view returns (address) {
        uint208 operatingAddressIdx = operatorToIdx[operator].upperLookup(timestamp);

        if (operatingAddressIdx == EMPTY_OPERATING_ADDRESS_IDX) {
            return address(0);
        }

        return idxToOperatingAddress[operatingAddressIdx];
    }

    function _updateOperatingAddress(address operator, address operatingAddress) internal {
        if (operatingAddressToOperator[operatingAddress] != address(0)) {
            revert DuplicateOperatingAddress();
        }

        uint208 newIdx = ++totalOperatingAddressCount;
        idxToOperatingAddress[newIdx] = operatingAddress;
        operatorToIdx[operator].push(Time.timestamp(), newIdx);
        operatingAddressToOperator[operatingAddress] = operator;
    }
}
