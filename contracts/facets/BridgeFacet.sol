// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IOmniPortal} from "@omni/contracts/contracts/interfaces/IOmniPortal.sol";

contract BridgeFacet {
    uint256 public count;
    uint256 public globalCount;
    uint256 public globalBlockNumber;

    mapping(string => uint256) public countByChain;

    IOmniPortal public omni;

    event Increment(uint256 count);

    function incrementRU() public {
        count += 1;
    }

    function incrementOnChainRU(string memory chain, address counter) public {
        omni = IOmniPortal(0xc0400275F85B45DFd2Cfc838dA8Ee4214B659e25);
        omni.sendXChainTx(
            chain, // destination rollup
            counter, // contract on destination rollup
            0, // msg.value
            100_000, // gas limit
            abi.encodeWithSignature("incrementRU()")
        );
    }

    function getCounter() public view returns (uint256) {
        return count;
    }

}