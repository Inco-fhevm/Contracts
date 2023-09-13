// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;
import "fhevm/lib/TFHE.sol";

contract TOTP {
    euint8 secretKey;
    address owner;

    constructor(bytes memory _secretKey) {
        secretKey = TFHE.asEuint8(_secretKey);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function validateTOTP(bytes calldata _encryptedTOTP, uint8 timestamp) public view {
        require(timestamp <= block.timestamp - 1000, "Timestamp not within range");
        euint8 encryptedTOTP = TFHE.asEuint8(_encryptedTOTP);
        ebool isValid = TFHE.eq(encryptedTOTP, TFHE.mul(TFHE.asEuint8(timestamp), secretKey));
        TFHE.req(isValid);
        // TODO: send message back to EVM chain via general messaging protocol
        // Send back bool and timestamp
    }
}


/*

contract SmartWallet {

    uint256 lastTOTP = timestamp
    address MAILBOX = 0x...ABC

    constructor(_mailbox) {
        MAILBOX = _mailbox
    }

    function execute() {
        require(timestamp + 3600 < block.timestamp, "Need OTP")
        return true;
    }

    function receiveOTP() {
        require(msg.owner == MAILBOX, "only mailbx");
        (bool, timestamp) = message..
        if (bool) {
            lastTOTP = timestamp;
        }
    }
}

/*