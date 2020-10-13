pragma solidity ^0.5.0;

import "../model/Governable.sol";

interface SFC {
    function delegations(address _from, uint256 _toStakerID) external view returns (uint256 createdEpoch, uint256 createdTime,
        uint256 deactivatedEpoch, uint256 deactivatedTime, uint256 amount, uint256 paidUntilEpoch, uint256 toStakerID);

    function stakers(uint256 _stakerID) external view returns (uint256 status, uint256 createdEpoch, uint256 createdTime,
        uint256 deactivatedEpoch, uint256 deactivatedTime, uint256 stakeAmount, uint256 paidUntilEpoch, uint256 delegatedMe, address dagAddress, address sfcAddress);

    function getStakerID(address _addr) external view returns (uint256);

    function stakeTotalAmount() external view returns (uint256);

    function delegationsTotalAmount() external view returns (uint256);
}

contract SFCToGovernable is Governable {
    SFC internal sfc = SFC(address(0xFC00FACE00000000000000000000000000000000));

    // Gets the total weight of voters
    function getTotalWeight() external view returns (uint256) {
        return sfc.stakeTotalAmount() + sfc.delegationsTotalAmount();
    }

    // Gets the received delegated weight
    function getReceivedWeight(address addr) external view returns (uint256) {
        uint256 stakerID = sfc.getStakerID(addr);
        if (stakerID == 0) {
            return 0;
        }
        (uint256 status, , , uint256 deactivatedEpoch, , uint256 stakeAmount, , uint256 delegatedMe, , address sfcAddress) = sfc.stakers(stakerID);
        if (deactivatedEpoch != 0 || status != 0 || sfcAddress != addr) {
            return 0;
        }
        return delegatedMe + stakeAmount;
    }

    // Gets the voting weight which is delegated from the specified address to the specified address
    function getWeight(address from, address to) external view returns (uint256) {
        uint256 toStakerID = sfc.getStakerID(to);
        if (toStakerID == 0) {
            return 0;
        }
        (uint256 status, , , uint256 toDeactivatedEpoch, , uint256 toStakeAmount, , , , address sfcAddress) = sfc.stakers(toStakerID);
        if (toDeactivatedEpoch != 0 || status != 0 || sfcAddress != to) {
            return 0;
        }
        if (from == to) {
            // get staker weight
            return toStakeAmount;
        } else {
            // get delegation weight
            (, , uint256 deactivatedEpoch, , uint256 amount, ,) = sfc.delegations(from, toStakerID);
            if (deactivatedEpoch != 0) {
                return 0;
            }
            return amount;
        }
    }
}
