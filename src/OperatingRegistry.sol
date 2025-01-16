// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

abstract contract OperatingRegistry {
    using Checkpoints for Checkpoints.Trace208;
    mapping(address => Checkpoints.Trace208) private operatorToIndex;
    mapping(address => address) private operatingToOperator;
    mapping(uint208 => address) private indexToOperating;
    
    uint208 private totalOperatingCount;
    uint208 internal constant EMPTY_OPERATING_ADDRESS_INDEX = 0;

    error DuplicateOperatingAddress();

    function _initOperatingAddress(address operator, address operating) internal {
        if (operatingToOperator[operating] != address(0)) {
            revert DuplicateOperatingAddress();
        }

        uint208 newIndex = ++totalOperatingCount;
        indexToOperating[newIndex] = operating;
        operatorToIndex[operator].push(Time.timestamp(), newIndex);
        operatingToOperator[operating] = operator;
    }
 
    function getOperatorWithOperatingAddress(address operating) public view returns (address) {
        return operatingToOperator[operating];
    }

    function getCurrentOperatingAddress(address operator) public view returns (address) {
        uint208 operatingIndex = operatorToIndex[operator].latest();

        if (operatingIndex == EMPTY_OPERATING_ADDRESS_INDEX) {
            return address(0);
        }

        return indexToOperating[operatingIndex];
    }

    function getOperatingAddressAt(address operator, uint48 timestamp) public view returns (address) {
        uint208 operatingIndex = operatorToIndex[operator].upperLookup(timestamp);

        if (operatingIndex == EMPTY_OPERATING_ADDRESS_INDEX) {
            return address(0);
        }

        return indexToOperating[operatingIndex];
    }

    function _updateOperatingAddress(address operator, address newOperating) internal {
        if (operatingToOperator[newOperating] != address(0)) {
            revert DuplicateOperatingAddress();
        }

        address currentOperating = getCurrentOperatingAddress(operator);
        uint208 operatingIndex = operatorToIndex[operator].latest();

        indexToOperating[operatingIndex] = newOperating;
        
        operatingToOperator[newOperating] = operator;

        delete operatingToOperator[currentOperating];
    }
}
