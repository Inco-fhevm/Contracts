// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

interface IInterchainAccountRouter {

    function callRemote(
        uint32 _destination,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address);

}

interface Card {
    function receiveCard(uint8 _card) external;
}

contract CardDealer is EIP712WithModifier {
    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;
    mapping (address => euint8) public encryptedCards;
    uint32 DestinationDomain;
    // Card contract address in destication chain
    address card;
    // InterchainExcuteRouter contract address in current chain
    address iexRouter;
    bytes32 messageId;
    // Virtul Account of HiddenCard contract in current chain
    address remote_contract;

    constructor() EIP712WithModifier("Authorization token", "1") {
    }

    function initialize(uint32 _DestinationDomain, address _card, address _iexRouter, address _remote_contract) public {
        DestinationDomain = _DestinationDomain;
        card = _card;
        iexRouter = _iexRouter;
        remote_contract = _remote_contract;
    }

    // A random encrypted uint8 is generated
    function getCard(address user) public {
        encryptedCards[user] = TFHE.randEuint8();
    }

    function viewCard(address user) external view returns (uint8) {
        return TFHE.decrypt(encryptedCards[user]);
    }

    function returnCard(address user) external view returns (uint8) {
        require(remote_contract == msg.sender, "not right remote contract");
        return TFHE.decrypt(encryptedCards[user]);
    }

    function sendCard(address user) public {
        Card _Card = Card(card);

        uint8 _card = TFHE.decrypt(encryptedCards[user]);

        messageId = IInterchainAccountRouter(iexRouter).callRemote(
            DestinationDomain,
            address(_Card),
            0,
            abi.encodeCall(_Card.receiveCard, (_card))
        );
    }

    function getICA(address _contract) public view returns(address) {
        return IInterchainAccountRouter(iexRouter).getRemoteInterchainAccount(DestinationDomain, _contract);
    }

    function remoteContractView() public view returns(address) {
        return remote_contract;
    }

    // EIP 712 signature is required to prove that the user is requesting to view his/her own card
    // card is decrypted then re-encrypted using a publicKey provided by the user client to make sure that RPC cannot peek. 
    // The user can decrypt their card with the respective privateKey (stored on client)
    function viewCard(bytes32 publicKey, bytes calldata signature) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(encryptedCards[msg.sender], publicKey, 0);
    }
}
