pragma solidity ^0.5.0;

library GetCode {
    function code(address _addr) internal view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    function codeSize(address _addr) internal view returns (uint size) {
        assembly {size := extcodesize(_addr)}
        return size;
    }

    function codeHash(address _addr) internal view returns (bytes32) {
        return keccak256(code(_addr));
    }
}