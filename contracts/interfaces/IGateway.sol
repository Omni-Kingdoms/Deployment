// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/RouterUtils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function currentVersion() external view returns (uint256);
}
