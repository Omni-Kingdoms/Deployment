// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants

    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant CONSTANT_POWER_THRESHOLD = 2791728742;
}
