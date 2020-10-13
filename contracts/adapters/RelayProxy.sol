pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";

contract RelayProxy {
    address public __destination;
    address public __owner;

    constructor(address _owner, address _destination) public {
        __owner = _owner;
        __destination = _destination;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DestinationChanged(address indexed previousRelay, address indexed newRelay);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function __transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Relay: new owner is the zero address");
        emit OwnershipTransferred(__owner, newOwner);
        __owner = newOwner;
    }

    function __setDestination(address newDestination) public onlyOwner {
        require(newDestination != address(0), "new owner address is the zero address");
        emit OwnershipTransferred(__destination, newDestination);
        __destination = newDestination;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == __owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Relay: caller is not the owner");
        _;
    }

    function() payable external {
        require(isOwner(), "Relay: caller is not the owner");
        _relay(__destination);
    }

    function _relay(address destination) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

            // Call the destination.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas, destination, callvalue, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // call returns 0 on error.
            case 0 {revert(0, returndatasize)}
            default {return (0, returndatasize)}
        }
    }
}