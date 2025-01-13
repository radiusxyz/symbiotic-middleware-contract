// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

abstract contract OperatingRegistry {
    using Checkpoints for Checkpoints.Trace208;
    mapping(address => Checkpoints.Trace208) private operatorToIdx;

    error DuplicateOperatingAddress();
    error NotInitializedOperatingAddress();

    mapping(address => address) private operatingToOperator;
    mapping(uint208 => address) private idxToOperating;
    
    uint208 private totalOperatingCount;
    uint208 internal constant EMPTY_OPERATING_ADDRESS_IDX = 0;

 
    function getOperatorWithOperatingAddress(address operating) public view returns (address) {
        return operatingToOperator[operating];
    }

    function getCurrentOperatingAddress(address operator) public view returns (address) {
        uint208 operatingIdx = operatorToIdx[operator].latest();

        if (operatingIdx == EMPTY_OPERATING_ADDRESS_IDX) {
            return address(0);
        }

        return idxToOperating[operatingIdx];
    }

    function getOperatingAddressAt(address operator, uint48 timestamp) public view returns (address) {
        uint208 operatingIdx = operatorToIdx[operator].upperLookup(timestamp);

        if (operatingIdx == EMPTY_OPERATING_ADDRESS_IDX) {
            return address(0);
        }

        return idxToOperating[operatingIdx];
    }

    function _initOperatingAddress(address operator, address operating) internal {
        if (operatingToOperator[operating] != address(0)) {
            revert DuplicateOperating();
        }

        uint208 newIdx = ++totalOperatingCount;
        idxToOperating[newIdx] = operating;
        operatorToIdx[operator].push(Time.timestamp(), newIdx);
        operatingToOperator[operating] = operator;
    }

    function _updateOperatingAddress(address operator, address operating) internal {
        if (operatingToOperator[operating] == address(0)) {
            revert NotInitializedOperatingAddress();
        }

        uint208 operatingIdx = operatorToIdx[operator].latest();

        idxToOperating[operatingIdx] = operating;
        operatingToOperator[operating] = operator;
    }
}
