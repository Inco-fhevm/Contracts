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

    function timestampView() public view returns (uint256) {
        return block.timestamp;
    }

    function validateTOTP(uint256 _encryptedTOTP, uint256 timestamp) public view returns(bool, uint256){
        require(timestamp <= block.timestamp - 1000, "Timestamp not within range");
        euint8 encryptedTOTP = TFHE.asEuint8(_encryptedTOTP);
        ebool isValid = TFHE.eq(encryptedTOTP, TFHE.mul(TFHE.asEuint8(timestamp), secretKey));
        TFHE.optReq(isValid);
        // TODO: send message back to EVM chain via general messaging protocol
        // Send back bool and timestamp
        return (TFHE.decrypt(isValid), block.timestamp);
    }
}