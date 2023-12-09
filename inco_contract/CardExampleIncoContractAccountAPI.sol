// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

contract HiddenCard is EIP712WithModifier {

    mapping (address => euint8) public encryptedCards;
    address public caller_contract;

    constructor() EIP712WithModifier("Authorization token", "1") {
    }

    function initialize(address _caller_contract) public {
        caller_contract = _caller_contract;
    }

    // A random encrypted uint8 is generated
    function getCard(address user) external {
        require(caller_contract == msg.sender, "not right caller contract");
        encryptedCards[user] = TFHE.randEuint8();
    }

    function viewCard(address user) external view returns (uint8) {
        return TFHE.decrypt(encryptedCards[user]);
    }
}