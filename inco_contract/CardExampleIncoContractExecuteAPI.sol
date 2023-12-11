// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

interface IInterchainExecuteRouter {

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);

}

contract HiddenCard is EIP712WithModifier {

    mapping (address => euint8) public encryptedCards;
    uint32 DestinationDomain;
    address public iexRouter;
    address public caller_contract;

    constructor() EIP712WithModifier("Authorization token", "1") {
    }

    function initialize(uint32 _DestinationDomain, address _caller_contract, address _iexRouter) public {
        DestinationDomain = _DestinationDomain;
        iexRouter = _iexRouter;
        caller_contract = _caller_contract;
    }

    // A random encrypted uint8 is generated
    function returnCard(address user) external returns(uint8) {
        require(caller_contract == msg.sender, "not right caller contract");
        encryptedCards[user] = TFHE.randEuint8();
        return TFHE.decrypt(encryptedCards[user]);
    }

    function viewCard(address user) external view returns (uint8) {
        return TFHE.decrypt(encryptedCards[user]);
    }

    function getICA(address _contract) public view returns(address) {
        return IInterchainExecuteRouter(iexRouter).getRemoteInterchainAccount(DestinationDomain, _contract);
    }
}