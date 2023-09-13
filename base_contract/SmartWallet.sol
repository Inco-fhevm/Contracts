// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

interface IInterchainQueryRouter {

    function query(
        uint32 _destination,
        address _to,
        bytes memory _data,
        bytes memory _callback
    ) external returns (bytes32);

}

interface TOTP {
    function validateTOTP(uint8 _encryptedTOTP, uint256 timestamp) external view returns (bool, uint256);
}

contract SmartWallet {

    uint32 constant ethereumDomain = 9000;
    uint256 lastTOTP = 0;
    address constant totp = 0x09bce27F2394Ae91049636566acFE7DceFb40CE3;
    address constant iqsRouter = 0x3c91A95Cb8D32933Bffc273Aaa6Fb57473438D6f;
    bytes32 messageId;

    // constructor(_iqsRouter) {
    //     iqsRouter = _iqsRouter;
    // }

    function execute() public view returns (bool) {
        require(lastTOTP + 3600 * 1000 < block.timestamp, "Need OTP");
        return true;
    }

    function calltimestamp(uint8 _encryptedTOTP) public {
        TOTP _validateTOTP = TOTP(totp);

        // uint32 _label = 32;
        bytes memory _callback = abi.encodePacked(this.receiveOTP.selector);
        // bytes memory _callback = abi.encodePacked(msg.sender);

        messageId = IInterchainQueryRouter(iqsRouter).query(
            ethereumDomain,
            address(_validateTOTP),
            abi.encodeCall(_validateTOTP.validateTOTP, (_encryptedTOTP, block.timestamp)),
            _callback
        );
    }

    function receiveOTP(bool flag, uint256 timestamp) public{
        require(msg.sender == iqsRouter, "only iqsRouter");
        // (bool, timestamp) = message..
        if (flag) {
            lastTOTP = timestamp;
        } else {
            lastTOTP = lastTOTP;
        }
    }

    function lastTOTPView() public view returns(uint256, uint256) {
        return (lastTOTP, block.timestamp);
    }
}