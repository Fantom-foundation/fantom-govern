// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;


/// @notice RelayProxy relays calls from the owner to the predefined destination contract
contract RelayProxy {
    address public __destination;
    address public __owner;

    constructor(address _owner, address _destination) {
        __owner = _owner;
        __destination = _destination;
    }

    /// @notice Emitted when ownership of the contract is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /// @notice Emitted when destination of the contract is changed.
    event DestinationChanged(address indexed previousRelay, address indexed newRelay);

    /// @notice Transfers ownership of the contract to a new account. - Can only be called by the current owner.
    /// @param newOwner The address to transfer ownership to.
    function __transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Relay: new owner is the zero address");
        emit OwnershipTransferred(__owner, newOwner);
        __owner = newOwner;
    }

    /// @notice Sets the destination of the relay - Can only be called by the current owner.
    /// @param newDestination The address to relay calls to.
    function __setDestination(address newDestination) public onlyOwner {
        require(newDestination != address(0), "new owner address is the zero address");
        // todo this should emit DestinationChanged
        emit OwnershipTransferred(__destination, newDestination);
        __destination = newDestination;
    }


    /// @dev Returns whether the caller is the current owner.
    function isOwner() internal view returns (bool) {
        return msg.sender == __owner;
    }


    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(isOwner(), "Relay: caller is not the owner");
        _;
    }


    fallback() payable external {
        require(isOwner(), "Relay: caller is not the owner");
        _relay(__destination);
    }

    function _relay(address destination) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the destination.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), destination, callvalue(), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }
}